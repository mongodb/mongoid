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
      # @param [ Array<Inclusion> ] inclusions The inclusions to load.
      # @param [ Array<Document> ] document The documents.
      def preload(inclusions, docs)
        inc_map = inclusions.group_by(&:inverse_class_name)
        docs_by_klass = { klass.to_s => docs.to_set }
        docs_by_name = {}
        queue = [ klass.to_s ]

        while klass = queue.shift
          if is = inc_map.delete(klass)
            is.each do |inc|
              queue << inc.class_name

              # If this class is nested in the inclusion tree, only load documents
              # for the association above it.
              docs = inc.previous? ? docs_by_name[inc._previous.name] : docs_by_klass[klass]
              docs ||= []

              res = inc.relation.eager_loader([inc._association], docs.to_a).run

              docs_by_name[inc.name] ||= [].to_set
              docs_by_name[inc.name].merge(res)

              res.group_by(&:class).each do |k, vs|
                docs_by_klass[k.to_s] ||= [].to_set
                docs_by_klass[k.to_s].merge(vs)
              end
            end
          end
        end
      end
    end
  end
end
