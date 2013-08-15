module Mongoid
  module Relations
    module Eager

      def preload(owner, relations, docs)

        relations.group_by do |rel_name|
          owner.reflect_on_association(rel_name).relation
        end.each do |relation, fields|
          relation.eager_load_klass.new(owner, fields, docs).run
        end
      end

      class Base

        def initialize(owner, relations, docs)
          @relations = relations.map { |rel| owner.reflect_on_association(rel) }
          @docs = docs
          @grouped_docs = {}
        end

        def run
          @relations.each do |relation|
            @metadata = relation
            preload
          end
        end

        def preload
          raise StandardError # TODO
        end

        def each_loaded_document
          @metadata.klass.any_in("_id" => keys_from_docs).each do |doc|
            yield doc
          end
        end

        def set_on_parent(id, element)
          grouped_docs[id].each do |d|
            method = @metadata.setter
            d.send(method, element)
          end
        end

        def grouped_docs
          @grouped_docs[@metadata.name] ||= @docs.group_by do |doc|
            group_by_key(doc)
          end
        end

        def keys_from_docs
          grouped_docs.keys
        end

        def group_by_key(doc)
          raise StandardError # TODO
        end
      end

    end
  end
end
