module Mongoid
  module Relations
    module Eager

      class HasAndBelongsToMany < Base

        def preload
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
