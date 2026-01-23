# frozen_string_literal: true
# rubocop:todo all

require "mongoid/association/eager"

module Mongoid
  module Association

    # This module defines the eager loading behavior for criteria.
    module EagerLoadable

      # Indicates whether the criteria has association
      # inclusions which should be eager loaded.
      #
      # @return [ true | false ] Whether to eager load.
      def eager_loadable?
        !criteria.inclusions.empty?
      end

      # Load the associations for the given documents.
      #
      # @param [ Array<Mongoid::Document> ] docs The documents.
      #
      # @return [ Array<Mongoid::Document> ] The given documents.
      def eager_load(docs)
        docs.tap do |d|
          if eager_loadable?
            preload(criteria.inclusions, d)
          end
        end
      end

      # Load the associations for the given documents using $lookup.
      #
      # @return [ Array<Mongoid::Document> ] The given documents.
      def eager_load_with_lookup
        preload_for_lookup(criteria)
      end

      # Load the associations for the given documents. This will be done
      # recursively to load the associations of the given documents'
      # associated documents.
      #
      # @param [ Array<Mongoid::Association::Relatable> ] associations
      #   The associations to load.
      # @param [ Array<Mongoid::Document> ] docs The documents.
      def preload(associations, docs)
        assoc_map = associations.group_by(&:inverse_class_name)
        docs_map = {}
        queue = [ klass.to_s ]

        # account for single-collection inheritance
        queue.push(klass.root_class.to_s) if klass != klass.root_class

        while klass = queue.shift
          if as = assoc_map.delete(klass)
            as.each do |assoc|
              queue << assoc.class_name

              # If this class is nested in the inclusion tree, only load documents
              # for the association above it. If there is no parent association,
              # we will include documents from the documents passed to this method.
              ds = docs
              if assoc.parent_inclusions.length > 0
                ds = assoc.parent_inclusions.map{ |p| docs_map[p].to_a }.flatten
              end

              res = assoc.relation.eager_loader([assoc], ds).run

              docs_map[assoc.name] ||= [].to_set
              docs_map[assoc.name].merge(res)
            end
          end
        end
      end

      # Load the associations for the given documents. This will be done
      # recursively to load the associations of the given documents'
      # associated documents.
      #
      # @param [ Array<Mongoid::Association::Relatable> ] associations
      #   The associations to load.
      # @param [ Array<Mongoid::Document> ] docs The documents.
      def preload_for_lookup(criteria)
        assoc_map = criteria.inclusions.group_by(&:inverse_class_name)

        # match first
        pipeline = criteria.selector.to_pipeline
        # then sort, skip, limit
        pipeline.concat(criteria.options.to_pipeline_for_lookup)

        # account for single-collection inheritance
        root_class = klass.root_class

        if assoc_map[klass.to_s]
          assoc_map[klass.to_s].each do |assoc|
            # Create a copy of the mapping for each top-level association to avoid mutation issues
            pipeline << create_pipeline(assoc, assoc_map.dup)
          end
        end

        if klass != root_class && assoc_map[root_class.to_s]
          assoc_map[root_class.to_s].each do |assoc|
            # Create a copy of the mapping for each top-level association to avoid mutation issues
            pipeline << create_pipeline(assoc, assoc_map.dup)
          end
        end

        Eager.new(criteria.inclusions, [], true, pipeline).run
      end

      def switch_local_and_foreign_fields?(association)
        association.is_a?(Mongoid::Association::Referenced::BelongsTo) ||
          association.is_a?(Mongoid::Association::Referenced::HasAndBelongsToMany)
      end

      def create_pipeline(current_assoc, mapping)
        # Build nested pipeline for children and ordering
        pipeline_stages = []

        # For belongs_to and has_and_belongs_to_many, the foreign key is on the current document
        # For has_many/has_one, the foreign key is on the related document
        if switch_local_and_foreign_fields?(current_assoc)
          local_field = current_assoc.foreign_key
          foreign_field = current_assoc.primary_key
        else
          local_field = current_assoc.primary_key
          foreign_field = current_assoc.foreign_key
        end
        
        # Build the 'as' field with embedded path prefix if needed
        as_field = current_assoc.name.to_s
        
        stage = {
          "$lookup" => {
            "from" => current_assoc.klass.collection.name,
            "localField" => local_field,
            "foreignField" => foreign_field,
            "as" => as_field
          }
        }
        
        # Add ordering if defined on the association, or default to _id for consistent order
        if current_assoc.order
          sort_spec = current_assoc.order.is_a?(Hash) ? current_assoc.order : { current_assoc.order => 1 }
          pipeline_stages << { "$sort" => sort_spec }
        end
        
        # Add nested lookups for child associations
        # Child associations don't need the embedded_path prefix since they're referenced from the looked-up document
        # Remove this class from the mapping to prevent infinite loops with circular references
        class_name = current_assoc.klass.to_s
        if child_assocs = mapping.delete(class_name)
          child_assocs.each do |child|
            pipeline_stages << create_pipeline(child, mapping)
          end
        end
        
        # Always add pipeline since we always have at least $sort
        stage["$lookup"]["pipeline"] = pipeline_stages
        
        stage
      end
    end
  end
end
