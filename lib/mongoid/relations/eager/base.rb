module Mongoid
  module Relations
    module Eager
      class Base
        def initialize(associations, docs)
          @associations = associations
          @docs = docs
          @grouped_docs = {}
        end

        def shift_metadata
          @metadata = @associations.shift
        end

        def run
          while shift_metadata
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
            set_relation(d, element)
          end
        end

        def set_relation(doc, element)
          doc.set_relation(@metadata.name, element)
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
