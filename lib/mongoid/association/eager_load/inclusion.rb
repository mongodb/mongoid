# frozen_string_literal: true

module Mongoid
  module Association
    module EagerLoad
      # Something an eager load contributes to the pipeline, in the role it plays
      # while the pipeline is built. A root is asked to contribute and the whole
      # tree follows by recursion. AssociationInclusion stands for a single
      # association; DiscriminatedInclusion stands for a name several subclasses
      # share.
      class Inclusion
        # Add this inclusion's stages to the destination.
        #
        # @param [ Array<Hash> ] destination The pipeline (or sub-pipeline) the
        #   stages are appended to.
        # @param [ Array<Mongoid::Association::Relatable> ] chain The embedded path
        #   accumulated from the ancestors above this inclusion (empty at the top).
        def contribute(destination, chain)
          raise NotImplementedError
        end
      end

      # An inclusion that stands for a single association. The LookupPipeline holds
      # the stage-building helpers the kinds lean on, and a node carries its own
      # children, so the pipeline is built by recursion from the roots downward.
      class AssociationInclusion < Inclusion
        class << self
          # Builds the right kind of inclusion for the association. Each subclass
          # decides whether it handles it (.for?); exactly one does.
          #
          # @param [ Mongoid::Association::Relatable ] association The inclusion.
          # @param [ LookupPipeline ] pipeline The pipeline being built.
          # @param [ Array<Inclusion> ] children The inclusions nested under it.
          #
          # @return [ AssociationInclusion ] The matching kind of inclusion.
          def for(association, pipeline, children)
            subclasses.find { |kind| kind.for?(association) }.new(association, pipeline, children)
          end

          # Whether this kind handles the given association.
          #
          # @return [ true | false ] Whether it handles it.
          def for?(association)
            raise NotImplementedError
          end
        end

        # @return [ Mongoid::Association::Relatable ] The association this stands for.
        attr_reader :association

        def initialize(association, pipeline, children)
          super()
          @association = association
          @pipeline = pipeline
          @children = children
        end
      end

      # A referenced inclusion: contributes a $lookup whose sub-pipeline holds its
      # own children. When it lives inside an embedded document (a non-empty
      # chain), the $lookup is distributed onto that embedded path instead of
      # standing at the top level.
      #
      # For a has_many :albums it contributes:
      #
      #   { '$lookup' => {
      #     'from' => 'albums',
      #     'localField' => '_id',        # the band's _id...
      #     'foreignField' => 'band_id',  # ...matched against each album's band_id
      #     'as' => 'albums',             # matches are written to this field
      #     'pipeline' => [
      #       { '$sort' => {
      #         '_id' => 1
      #       } },
      #       <children>
      #     ]
      #   } }
      class JoinedInclusion < AssociationInclusion
        class << self
          # The default kind: a referenced, non-polymorphic association, i.e. the
          # one no sibling kind claims.
          def for?(association)
            (superclass.subclasses - [ self ]).none? { |kind| kind.for?(association) }
          end
        end

        def contribute(destination, chain)
          stage = @pipeline.lookup_stage_for(@association)
          @children.each { |child| child.contribute(stage['$lookup']['pipeline'], []) }

          if chain.empty?
            destination << stage
          else
            destination.concat(@pipeline.distribute(@association, chain, stage))
          end
        end
      end

      # An embedded inclusion: it rides inside its own document, so it adds no
      # stage of its own. Its children contribute to the same destination, with
      # this document appended to their embedded path.
      #
      # For Computer.eager_load(port: :device) the :port inclusion emits nothing;
      # it hands the path [ :port ] to :device, which EmbeddedDistributor then
      # turns into stages.
      class EmbeddedInclusion < AssociationInclusion
        class << self
          def for?(association)
            association.embedded?
          end
        end

        def contribute(destination, chain)
          @children.each { |child| child.contribute(destination, chain + [ @association ]) }
        end
      end

      # A polymorphic inclusion: its target collection varies per document, so it
      # can't be a $lookup. It adds nothing here; PolymorphicPreloader resolves it
      # after the roots are materialized.
      class DeferredInclusion < AssociationInclusion
        class << self
          def for?(association)
            association.polymorphic?
          end
        end

        def contribute(destination, chain); end
      end
    end
  end
end
