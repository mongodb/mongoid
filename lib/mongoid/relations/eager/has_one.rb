# encoding: utf-8
module Mongoid
  module Relations
    module Eager

      class HasOne < Base

        def preload
          @docs.each do |d|
            set_relation(d, nil)
          end

          each_loaded_document do |doc|
            id = doc.send(key)
            set_on_parent(id, doc)
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
