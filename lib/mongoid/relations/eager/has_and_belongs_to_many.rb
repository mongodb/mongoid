# encoding: utf-8
module Mongoid
  module Relations
    module Eager

      class HasAndBelongsToMany < Base

        def preload
          @docs.each do |d|
            set_relation(d, [])
          end

          entries = {}
          each_loaded_document do |doc|
            entries[doc.send(key)] = doc
          end

          @docs.each do |d|
            keys = d.send(group_by_key)
            docs = entries.values_at(*keys)
            set_relation(d, docs)
          end
        end

        def keys_from_docs
          keys = Set.new
          @docs.each do |d|
            keys += d.send(group_by_key)
          end
          keys.to_a
        end

        def set_relation(doc, element)
          doc.__build__(@metadata.name, element, @metadata)
        end

        def group_by_key
          @metadata.foreign_key
        end

        def key
          @metadata.primary_key
        end
      end
    end
  end
end
