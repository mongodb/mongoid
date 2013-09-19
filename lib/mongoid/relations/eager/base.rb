module Mongoid
  module Relations
    module Eager

      class Base

        def initialize(owner, relations, docs)
          @relations = relations
          @docs = docs
          @grouped_docs = {}
        end

        def shift_relation
          @metadata = @relations.shift
        end

        def run
          while shift_relation
            preload
          end
        end

        def preload
          raise NotImplementedError
        end

        def each_loaded_document
          @metadata.klass.any_in(key => keys_from_docs).each do |doc|
            yield doc
          end
        end

        def set_on_parent(id, element)
          grouped_docs[id].each do |d|
            d.set_relation(@metadata.name, element)
          end
        end

        def grouped_docs
          @grouped_docs[@metadata.name] ||= @docs.group_by do |doc|
            doc.send(group_by_key)
          end
        end

        def keys_from_docs
          grouped_docs.keys
        end

        def group_by_key(doc)
          raise NotImplementedError
        end
      end

    end
  end
end
