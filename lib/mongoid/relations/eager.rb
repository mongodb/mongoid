require "mongoid/relations/eager/belongs_to"

module Mongoid
  module Relations
    module Eager

      attr_accessor :eager_loaded

      def with_eager_loading(document)
        selecting do
          return nil unless document
          doc = Factory.from_db(klass, document, criteria.object_id)
          eager_load_one(doc) if eager_loadable?(doc)
          doc
        end
      end

      def eager_load_one(doc)
        eager_load([doc])
      end

      def eager_loadable?(document = nil)
        return false if criteria.inclusions.empty?
        document ? !inclusions_loaded?(document) : !eager_loaded
      end

      def eager_load(docs)
        preload(klass, criteria.inclusions, docs)
        self.eager_loaded = true
      end

      def preload(owner, relations, docs)

        relations.group_by do |metadata|
          metadata.relation
        end.each do |relation, fields|
          relation.eager_load_klass.new(owner, fields, docs).run
        end
      end

    end
  end
end
