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
            execute_preload(criteria.inclusions, d)
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
        incs = associations.map{ |a| Mongoid::Criteria::Includable::Inclusion.new(a) }
        execute_preload(incs, docs)
      end

      # Execute the preload.
      #
      # @param [ Array<Inclusion> ] inclusions The inclusions to load.
      # @param [ Array<Document> ] document The documents.
      #
      # @api private
      def execute_preload(inclusions, docs)
        inc_map = inclusions.group_by(&:inverse_class_name)
        docs_map = {}
        queue = [ klass.to_s ]

        while klass = queue.shift
          if is = inc_map.delete(klass)
            is.each do |inc|
              queue << inc.class_name

              # If this class is nested in the inclusion tree, only load documents
              # for the association above it. If there is no parent association,
              # we will include documents from the documents passed to this method.
              docs = inc.parent? ? docs_map[inc.parent] : docs

              res = inc.relation.eager_loader([inc.association], docs.to_a).run

              docs_map[inc.name] ||= [].to_set
              docs_map[inc.name].merge(res)
            end
          end
        end
      end
    end
  end
end
