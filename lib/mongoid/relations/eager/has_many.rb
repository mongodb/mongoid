module Mongoid
  module Relations
    module Eager

      class HasMany < Base

        def preload
          entries = Hash.new { |hash, key| hash[key] = [] }
          each_loaded_document do |doc|
            fk = doc.send(key)
            entries[fk] << doc
          end

          entries.each do |id, docs|
            set_on_parent(id, docs)
          end
        end

        def group_by_key
          @metadata.primary_key
        end

        def key
          @metadata.foreign_key
        end
      end
    end
  end
end
