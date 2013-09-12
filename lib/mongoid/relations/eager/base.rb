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
          p grouped_docs
          p key
          p @metadata.klass
          @metadata.klass.any_in(key => keys_from_docs).each do |doc|
            yield doc
          end
        end

        def set_on_parent(id, doc)
          p id
          p grouped_docs
          grouped_docs[id].each do |d|
            method = @metadata.setter
            d.send(method, doc)
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
          raise StandardError # TODO
        end
      end

    end
  end
end
