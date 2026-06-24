# frozen_string_literal: true

module Mongoid
  module Association
    module EagerLoad
      # The targets of a polymorphic belongs_to, indexed as
      # { type => { primary_key => document } }. Each subclass reaches the types that
      # live in one place (the root's database or elsewhere); .for resolves the whole
      # set, routing each type to the subclass that can reach it.
      #
      # @api private
      class PolymorphicTargets
        class << self
          # Resolve every polymorphic target for the foreign keys grouped by type.
          # The types whose documents share the root's database are fetched together
          # in one $facet; those living elsewhere are read through their own models.
          #
          # @param [ Mongoid::Association::Relatable ] association The polymorphic inclusion.
          # @param [ Hash ] keys_by_type The foreign keys grouped by type.
          # @param [ Class ] root_class The class being queried.
          #
          # @return [ Hash ] The targets, as { type => { primary_key => document } }.
          def for(association, keys_by_type, root_class)
            here, elsewhere = keys_by_type.partition do |type, _keys|
              in_root_database?(association, type, root_class)
            end
            same_database = SameDatabaseTargets.new(association, here.to_h, root_class)
            other_databases = OtherDatabaseTargets.new(association, elsewhere.to_h)
            same_database.fetch.merge(other_databases.fetch)
          end

          private

          # Whether the type's model shares the root's database (and client): exactly
          # what a $lookup from the root collection can reach.
          def in_root_database?(association, type, root_class)
            model = association.resolver.model_for(type)
            model.client_name == root_class.client_name &&
              model.database_name == root_class.database_name
          end
        end

        def initialize(association, keys_by_type)
          @association = association
          @keys_by_type = keys_by_type
        end

        # @return [ Hash ] The targets, as { type => { primary_key => document } }.
        def fetch
          raise NotImplementedError
        end

        private

        def primary_key
          @association.primary_key
        end

        def model_for(type)
          @association.resolver.model_for(type)
        end

        # The raw documents instantiated and indexed by their primary key.
        def indexed(documents, model)
          documents.map { |document| Factory.from_db(model, document) }
                   .index_by { |document| document.send(primary_key) }
        end
      end

      # Targets that live in the root's own database. A $lookup can reach them, so
      # every type is fetched together in one $facet aggregation against the root
      # collection.
      #
      # For { 'Printer' => [ id1 ], 'Scanner' => [ id2 ] } it runs:
      #
      #   [
      #     { '$limit' => 1 },   # one input doc, so each facet branch runs once
      #     { '$facet' => {      # run one $lookup per type within a single query
      #       'Printer' => [ { '$lookup' => { 'from' => 'printers', ... } }, ... ],
      #       'Scanner' => [ { '$lookup' => { 'from' => 'scanners', ... } }, ... ]
      #     } }
      #   ]
      #
      # @api private
      class SameDatabaseTargets < PolymorphicTargets
        def initialize(association, keys_by_type, root_class)
          super(association, keys_by_type)
          @root_class = root_class
        end

        # @return [ Hash ] The targets, as { type => { primary_key => document } }.
        def fetch
          return {} if @keys_by_type.empty?

          aggregated = @root_class.collection.aggregate([ { '$limit' => 1 }, { '$facet' => facets } ]).first
          aggregated.to_h do |type, branch|
            # $limit => 1 makes each branch yield a single wrapper holding the matches.
            [ type, indexed(branch.first['matches'], model_for(type)) ]
          end
        end

        private

        def facets
          @keys_by_type.to_h do |type, keys|
            [ type, branch_for(model_for(type).collection.name, keys) ]
          end
        end

        # One $facet branch: the documents in +collection_name+ whose primary key
        # is among +keys+, exposed under "matches".
        def branch_for(collection_name, keys)
          [
            { '$lookup' => {
              'from' => collection_name,
              'pipeline' => [
                { '$match' => {
                  primary_key => { '$in' => keys.uniq }
                } }
              ],
              'as' => 'matches'
            } },
            { '$project' => {
              '_id' => 0,
              'matches' => 1
            } }
          ]
        end
      end

      # Targets kept in another database (or cluster), which a $lookup cannot
      # reach. Each type is read directly through its own model, which connects
      # with that model's client.
      #
      # For { 'Scanner' => [ id2 ] } it runs, on the Scanner model's own client:
      #   scanners.find('_id' => { '$in' => [ id2 ] })
      #
      # @api private
      class OtherDatabaseTargets < PolymorphicTargets
        # @return [ Hash ] The targets, as { type => { primary_key => document } }.
        def fetch
          @keys_by_type.to_h do |type, keys|
            model = model_for(type)
            documents = model.collection.find(primary_key => { '$in' => keys.uniq })
            [ type, indexed(documents, model) ]
          end
        end
      end
    end
  end
end
