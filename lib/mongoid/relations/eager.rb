# encoding: utf-8
require "mongoid/relations/eager/base"
require "mongoid/relations/eager/belongs_to"
require "mongoid/relations/eager/has_one"
require "mongoid/relations/eager/has_many"
require "mongoid/relations/eager/has_and_belongs_to_many"

module Mongoid
  module Relations
    module Eager

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
            relation.eager_load_klass.new(association, docs).run
          end
        end
      end
    end
  end
end
