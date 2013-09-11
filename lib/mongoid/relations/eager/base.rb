module Mongoid
  module Relations
    module Eager

      class Base

        def initialize(owner, relations, docs)
          @relations = relations
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
          raise StandardError, "Implement preload" # TODO
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
