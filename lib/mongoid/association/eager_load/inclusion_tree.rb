# frozen_string_literal: true

require 'mongoid/association/eager_load/discriminated_inclusion'
require 'mongoid/association/eager_load/inclusion'

module Mongoid
  module Association
    module EagerLoad
      # The tree of nested inclusions an eager load asks to load. Built from the
      # criteria's inclusions, it contributes each root node's stages to the
      # pipeline, with each node already carrying its own children.
      #
      # Each root branch is built from its own copy of the inclusions, and an
      # inclusion is removed as it is placed, so it lands once per branch even if
      # more than one parent in that branch points at it, and a circular chain of
      # inclusions can't loop forever.
      class InclusionTree
        class << self
          def from(inclusions, pipeline)
            new(inclusions, pipeline, inclusions.to_h { |association| [ association.name, association ] })
          end

          private :new
        end

        def initialize(inclusions, pipeline, by_name)
          @inclusions = inclusions
          @pipeline = pipeline
          @by_name = by_name
        end

        # Contribute each root inclusion's stages to the pipeline. Each root carries
        # its own children, so the whole tree is appended by recursion from the
        # roots downward.
        #
        # @param [ Array<Hash> ] destination The pipeline the stages are appended to.
        def contribute_to(destination)
          roots.each { |root| root.contribute(destination, []) }
        end

        private

        # A name that more than one subclass defines (with different targets) can't
        # share one $lookup field, so its nodes -- each carrying its own children --
        # are grouped and routed by the discriminator instead of becoming separate,
        # overwriting roots.
        def roots
          top_level.group_by(&:name).map do |_name, associations|
            nodes = associations.map { |association| node(association, @inclusions.dup) }
            nodes.one? ? nodes.first : DiscriminatedInclusion.new(nodes)
          end
        end

        # The inclusions that no other inclusion is the parent of.
        def top_level
          @inclusions.reject do |association|
            association.parent_inclusions.any? { |name| @by_name.key?(name) }
          end
        end

        def node(association, available)
          children = take_children(association, available).map { |child| node(child, available) }
          AssociationInclusion.for(association, @pipeline, children)
        end

        # The still-available inclusions parented to +association+, removed as they
        # are taken so each lands once on this branch. A child belongs here when it
        # names this association as its parent and its owner shares the target's
        # class hierarchy, which tells apart children of two unrelated subclasses
        # that share an association name.
        def take_children(association, available)
          children = available.select do |candidate|
            candidate.parent_inclusions.include?(association.name) &&
              same_hierarchy?(association.klass, candidate.inverse_class)
          end
          available.reject! { |candidate| children.include?(candidate) }
          children
        end

        # Whether two classes belong to the same inheritance chain (one is the
        # other, an ancestor of it, or a descendant of it).
        def same_hierarchy?(one, other)
          one <= other || other <= one
        end
      end
    end
  end
end
