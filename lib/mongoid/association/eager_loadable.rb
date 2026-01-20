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

        puts "why am i here"

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

        # Determine if we're querying embedded documents
        # If so, we need to track the embedded path prefix for lookup 'as' fields
        embedded_path = nil
        if criteria.embedded? && criteria.association
          pipeline, embedded_path = handle_embedded(pipeline, criteria)
        end

        # account for single-collection inheritance
        root_class = klass.root_class

        if assoc_map[klass.to_s]
          assoc_map[klass.to_s].each do |assoc|
            pipeline << create_pipeline(assoc, assoc_map, embedded_path)
          end
        end

        if klass != root_class && assoc_map[root_class.to_s]
          assoc_map[root_class.to_s].each do |assoc|
            pipeline << create_pipeline(assoc, assoc_map, embedded_path)
          end
        end

        pipeline << { "$replaceRoot" => { "newRoot" => embedded_path ? "$#{embedded_path}" : "$$ROOT" } } if embedded_path

        pp pipeline

        Eager.new(criteria.inclusions, [], true, pipeline).run
      end

      # return pipeline and embedded
      def handle_embedded(pipeline, criteria)
        embedded_path = nil
        embedded_steps = []
        # For embedded documents, we need to match the parent document
        # The parent_id should be in the embedded collection's base criteria
        unless criteria.documents.empty?
          document = criteria.documents[0]
          while document && document.embedded? && criteria.documents[0].respond_to?(:_parent) && criteria.documents[0]._parent
            embedded_field = document._association.store_as || document._association.name.to_s if document._association
            embedded_steps << embedded_field

            document = document._parent
          end
        end

        # build the embedded path
        embedded_steps.reverse.each do |step|
          embedded_path = if embedded_path.blank?
            step
          else
            "#{embedded_path}.#{step}"
          end
          pipeline << {
            "$unwind" => "$#{embedded_path}"
          }
        end

        # match the outermost document id
        if pipeline.empty? || !pipeline.first.key?("$match")
          pipeline.unshift({ "$match" => { "_id" => document.id } })
        end

        return pipeline, embedded_path
      end

      def create_pipeline(current_assoc, mapping, embedded_path = nil, prefix = nil)
        # Build nested pipeline for children and ordering
        pipeline_stages = []

        # If embeds_many, set the prefix and continue recursively
        if current_assoc.is_a?(Mongoid::Association::Embedded::EmbedsMany || Mongoid::Association::Embedded::EmbedsOne)
          new_prefix = if prefix
            "#{prefix}.#{current_assoc.name}"
          else
            current_assoc.name.to_s
          end
          pipeline_stages << create_pipeline(nil, mapping, embedded_path, new_prefix)
          return pipeline_stages
        end

        # For belongs_to and has_and_belongs_to_many, the foreign key is on the current document
        # For has_many/has_one, the foreign key is on the related document
        if current_assoc.is_a?(Mongoid::Association::Referenced::BelongsTo) || current_assoc.is_a?(Mongoid::Association::Referenced::HasAndBelongsToMany)
          local_field = current_assoc.foreign_key
          foreign_field = current_assoc.primary_key
        else
          local_field = current_assoc.primary_key
          foreign_field = current_assoc.foreign_key
        end

        full_prefix = [embedded_path, prefix].compact.join(".")
        
        # Build the 'as' field with embedded path prefix if needed
        as_field = if !full_prefix.blank?
          "#{full_prefix}.#{current_assoc.name}"
        else
          current_assoc.name.to_s
        end
        
        stage = {
          "$lookup" => {
            "from" => current_assoc.klass.collection.name,
            "localField" => full_prefix.empty? ? local_field : "#{full_prefix}.#{local_field}",
            "foreignField" => foreign_field,
            "as" => as_field
          }
        }
        
        # Add ordering if defined on the association, or default to _id for consistent order
        if current_assoc.order
          sort_spec = current_assoc.order.is_a?(Hash) ? current_assoc.order : { current_assoc.order => 1 }
          pipeline_stages << { "$sort" => sort_spec }
        else
          # Default to sorting by _id to maintain insertion order consistency
          pipeline_stages << { "$sort" => { "_id" => 1 } }
        end
        
        # Add nested lookups for child associations
        # Child associations don't need the embedded_path prefix since they're referenced from the looked-up document
        class_name = current_assoc.klass.to_s
        if mapping[class_name]
          mapping[class_name].each do |child|
            pipeline_stages << create_pipeline(child, mapping, nil)
          end
        end
        
        # Always add pipeline since we always have at least $sort
        stage["$lookup"]["pipeline"] = pipeline_stages
        
        stage
      end
    end
  end
end
