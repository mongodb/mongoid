# frozen_string_literal: true

require 'mongoid/association/eager_load/embedded_distributor'
require 'mongoid/association/eager_load/inclusion_tree'

module Mongoid
  module Association
    module EagerLoad
      # Builds the aggregation pipeline that eager-loads a criteria's inclusions
      # with $lookup.
      #
      # It starts with the criteria's own match/sort/skip/limit, then lets each
      # root of the inclusion tree contribute its stages. This object owns the
      # stage-building helpers; how each inclusion contributes is the inclusion's
      # own business (see Inclusion).
      #
      # For Band.eager_load(albums: :tracks) the result is roughly:
      #
      #   [ <criteria match / sort / skip / limit>,
      #     { '$lookup' => {                 # JoinedInclusion(:albums)
      #       'from' => 'albums',
      #       'localField' => '_id',
      #       'foreignField' => 'band_id',
      #       'as' => 'albums',
      #       'pipeline' => [
      #         { '$sort' => {
      #           '_id' => 1
      #         } },
      #         { '$lookup' => {             # JoinedInclusion(:tracks), nested
      #           'as' => 'tracks',
      #           'pipeline' => [
      #             { '$sort' => {
      #               '_id' => 1
      #             } }
      #           ]
      #         } }
      #       ]
      #     } } ]
      class LookupPipeline
        def initialize(criteria)
          @criteria = criteria
        end

        # @return [ Array<Hash> ] The aggregation pipeline stages.
        def stages
          pipeline = @criteria.selector.to_pipeline
          pipeline.concat(@criteria.options.to_pipeline_for_lookup)
          InclusionTree.from(@criteria.inclusions, self).contribute_to(pipeline)
          pipeline
        end

        # The $lookup stage for a referenced inclusion: its key fields, a
        # discriminator match when the target shares its collection with sibling
        # subclasses, and an order. Children are added by the inclusion itself.
        #
        # @param [ Mongoid::Association::Relatable ] association The inclusion.
        #
        # @return [ Hash ] The $lookup stage.
        def lookup_stage_for(association)
          local_field, foreign_field = lookup_fields(association)
          sub_pipeline = []
          sub_pipeline << discriminator_match(association) if association.klass.hereditary?
          sub_pipeline << order(association)
          { '$lookup' => {
            'from' => association.klass.collection.name,
            'localField' => local_field,
            'foreignField' => foreign_field,
            'as' => association.name.to_s,
            'pipeline' => sub_pipeline
          } }
        end

        # Builds the stages that distribute a referenced inclusion living inside an
        # embedded document onto that document.
        #
        # @param [ Mongoid::Association::Relatable ] association The inclusion.
        # @param [ Array<Mongoid::Association::Relatable> ] chain The embedded path.
        # @param [ Hash ] lookup_stage The $lookup stage for the association.
        #
        # @return [ Array<Hash> ] The stages to append.
        def distribute(association, chain, lookup_stage)
          EmbeddedDistributor.for(association: association, chain: chain, lookup_stage: lookup_stage).stages
        end

        private

        # When the association stores the foreign key on the current document
        # (belongs_to, has_and_belongs_to_many) the local field is that key; for
        # the others (has_many, has_one) the key is on the related document.
        def lookup_fields(association)
          if association.stores_foreign_key?
            [ association.foreign_key, association.primary_key ]
          else
            [ association.primary_key, association.foreign_key ]
          end
        end

        def discriminator_match(association)
          target = association.klass
          { '$match' => {
            target.discriminator_key => { '$in' => target._types }
          } }
        end

        def order(association)
          unless association.order
            return { '$sort' => {
              '_id' => 1
            } }
          end

          ordering = association.order
          ordering = { ordering => 1 } unless ordering.is_a?(Hash)
          { '$sort' => ordering }
        end
      end
    end
  end
end
