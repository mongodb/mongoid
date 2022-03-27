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
      # @param [ Array<Association> ] association The associations to load.
      # @param [ Array<Document> ] document The documents.
      def preload(associations, docs)
        assoc_map = associations.group_by(&:inverse_class_name)
        docs_map = { klass.to_s => docs.to_set }
        queue = [ klass.to_s ]

        while klass = queue.shift
          if as = assoc_map.delete(klass)
            as.group_by(&:relation)
            .each do |relation, assocs|
              assocs.each { |a| queue << a.class_name }

              docs = docs_map[klass] || []
              res = relation.eager_loader(assocs, docs.to_a).run

              res.group_by(&:class).each do |k, vs|
                docs_map[k.to_s] ||= [].to_set
                docs_map[k.to_s].merge(vs)
              end
            end
          end
        end
      end
    end
  end
end
