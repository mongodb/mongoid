module Mongoid
  module Relations
    module Eager

      class BelongsTo < Base

        def preload
          each_loaded_document do |doc|
            set_on_parent(doc.id, doc)
          end
        end

        def group_by_key(doc)
          doc.send(@metadata.foreign_key)
        end
      end
    end
  end
end
