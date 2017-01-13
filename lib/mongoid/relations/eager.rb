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
        grouped_relations = relations.group_by do |metadata|
          metadata.inverse_class_name
        end
        grouped_relations.keys.each do |_klass|
          grouped_relations[_klass] = grouped_relations[_klass].group_by do |metadata|
            metadata.relation
          end
        end
        grouped_relations.each do |_klass, associations|
          docs = associations.collect do |_relation, association|
            _relation.eager_load_klass.new(association, docs).run
          end.flatten
        end
      end
    end
  end
end
