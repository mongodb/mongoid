module Mongoid
  module Relations
    module Eager

      class HasAndBelongsToMany < Base

        def preload
          @docs.each do |d|
            set_relation(d, [])
          end

          entries = Hash.new { |hash, key| hash[key] = [] }
          each_loaded_document do |doc|

            ids = doc.send(key)
            ids.each do |id|
              entries[id] << doc
            end
          end

          entries.each do |id, docs|
            set_on_parent(id, docs)
          end
        end

        def set_relation(doc, element)
          doc.__build__(@metadata.name, element, @metadata)
        end

        def group_by_key
          @metadata.primary_key
        end

        def key
          @metadata.inverse_foreign_key
        end
      end
    end
  end
end
