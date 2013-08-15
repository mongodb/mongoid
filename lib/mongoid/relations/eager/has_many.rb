module Mongoid
  module Relations
    module Eager

      class HasMany

        def preload
          entries = {}
          each_loaded_document do |doc|
            fk = doc.__send__(@metadata.foreign_key)
            entries[fk] ||= []
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
