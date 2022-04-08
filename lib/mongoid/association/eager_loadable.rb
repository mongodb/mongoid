# frozen_string_literal: true

require "mongoid/association/referenced/eager"

module Mongoid
  module Association

    # This module defines the eager loading behavior for criteria.
    module EagerLoadable

      def eager_loadable?
        !criteria.inclusions.empty?
      end

      def eager_load(docs)
        docs.tap do |d|
          if eager_loadable?
            preload(criteria.inclusions, d)
          end
        end
      end

      # Load the associations for the given documents. This will be done
      # recursively to load the associations of the given documents'
      # subdocuments.
      #
      # @param [ Array<Association> ] associations The associations to load.
      # @param [ Array<Document> ] document The documents.
      def preload(associations, docs)
        assoc_map = associations.group_by(&:inverse_class_name)
        docs_map = {}
        queue = [ klass.to_s ]

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
    end
  end
end
