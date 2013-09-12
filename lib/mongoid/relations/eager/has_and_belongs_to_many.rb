module Mongoid
  module Relations
    module Eager

      class HasAndBelongsToMany < Base

        def preload
          entries = Hash.new { |hash, key| hash[key] = [] }
          each_loaded_document do |doc|
#            p doc
            id = doc.send(group_by_key)
            entries[id] << doc
          end

          entries.each do |id, docs|
            set_on_parent(id, docs)
          end
        end

        def group_by_key
          @metadata.primary_key
        end

        def key
          "account_ids"
          #@metadata.foreign_key
        end
      end
    end
  end
end
