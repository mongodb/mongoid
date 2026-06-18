# frozen_string_literal: true

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

        def roots
          top_level.map { |association| node(association, @inclusions.dup) }
        end

        # The inclusions that no other inclusion is the parent of.
        def top_level
          @inclusions.reject do |association|
            association.parent_inclusions.any? { |name| @by_name.key?(name) }
          end
        end

        def node(association, available)
          children = take_children(association, available).map { |child| node(child, available) }
          Inclusion.for(association, @pipeline, children)
        end

        # The still-available inclusions parented to +association+, removed as they
        # are taken so each lands once on this branch. Matched by the real
        # parent-child link, not by class, so a sibling branch isn't pulled in when
        # an association points at a superclass of the queried subclass.
        def take_children(association, available)
          children = available.select { |candidate| candidate.parent_inclusions.include?(association.name) }
          available.reject! { |candidate| children.include?(candidate) }
          children
        end
      end
    end
  end
end
