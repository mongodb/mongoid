module Mongoid
  module Relations
    module Eager

      class HasMany

        def preload
          entries = Hash.new([])
          each_loaded_document do |doc|
            fk = doc.send(@metadata.foreign_key)
            entries[fk] << doc
          end

          entries.each do |id, docs|
            set_on_parent(id, docs)
          end
        end

        def group_by_key(doc)
          doc.id
        end
      end
    end
  end
end
