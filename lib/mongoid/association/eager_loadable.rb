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

              res = assoc.relation.eager_loader([assoc], ds, false).run

              docs_map[assoc.name] ||= [].to_set
              docs_map[assoc.name].merge(res)
            end
          end
        end
      end

      private def name_to_prefix(name, children_to_parents, curr_prefix = "")
        if !children_to_parents.key?(name)
          curr_prefix
        else
          name_to_prefix(children_to_parents[name], children_to_parents, "#{children_to_parents[name]}." + curr_prefix)
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
        # pp criteria.inclusions
        assoc_map = criteria.inclusions.group_by(&:inverse_class_name)
        children_to_parents = {}

        # pp assoc_map
        queue = [ klass.to_s ]
        pipeline = criteria.selector.to_pipeline

        # account for single-collection inheritance
        root_class = klass.root_class
        queue.push(klass.root_class.to_s) if klass != root_class

        while klass = queue.shift
          if as = assoc_map.delete(klass)
            as.each do |assoc|
              if assoc.inverse_class_name && assoc.inverse_class_name != root_class.name
                children_to_parents[assoc.name.to_s] = assoc.inverse_class_name.tableize
              end
              queue << assoc.class_name

              # get prefix from assoc.name
              prefix = name_to_prefix(assoc.name.to_s, children_to_parents, "")
              
              pipeline << {
                "$lookup" => {
                  "from" => assoc.klass.collection.name,
                  "localField" => "#{prefix}#{assoc.primary_key}",
                  "foreignField" => assoc.foreign_key,
                  "as" => "#{prefix}#{assoc.name}"
                }
              }
            end
          end
        end
        Eager.new(criteria.inclusions, [], true, pipeline).run
      end
    end
  end
end
