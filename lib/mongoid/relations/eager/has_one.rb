module Mongoid
  module Relations
    module Eager

      class HasOne

        def preload
          each_loaded_document do |doc|
            fk = doc.__send__(@metadata.foreign_key)
            set_on_parent(fk, doc)
          end
        end

        def group_by_key(doc)
          doc.id
        end
      end
    end
  end
end
