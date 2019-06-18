# frozen_string_literal: true
# encoding: utf-8

require "mongoid/association/referenced/eager"

module Mongoid
  module Association

    # This module defines the eager loading behavior for criteria.
    #
    # @since 7.0
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

      def preload(relations, docs)
        relations.group_by(&:inverse_class_name)
            .values
            .each do |associations|
          associations.group_by(&:relation)
              .each do |relation, association|
            relation.eager_loader(association, docs).run
          end
        end
      end
    end
  end
end
