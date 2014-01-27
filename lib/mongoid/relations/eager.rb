# encoding: utf-8
require "mongoid/relations/eager/base"
require "mongoid/relations/eager/belongs_to"
require "mongoid/relations/eager/has_one"
require "mongoid/relations/eager/has_many"
require "mongoid/relations/eager/has_and_belongs_to_many"

module Mongoid
  module Relations
    module Eager

      attr_accessor :eager_loaded

      def with_eager_loading(document)
        return nil unless document
        doc = Factory.from_db(klass, document, criteria.options[:fields])
        eager_load_one(doc)
        doc
      end

      def eager_load_one(doc)
        eager_load([doc])
      end

      def eager_loadable?(document = nil)
        return false if criteria.inclusions.empty?
        !eager_loaded
      end

      def eager_load(docs)
        return false unless eager_loadable?
        preload(criteria.inclusions, docs)
        self.eager_loaded = true
      end

      def preload(relations, docs)

        relations.group_by do |metadata|
          metadata.relation
        end.each do |relation, associations|
          relation.eager_load_klass.new(associations, docs).run
        end
      end
    end
  end
end
