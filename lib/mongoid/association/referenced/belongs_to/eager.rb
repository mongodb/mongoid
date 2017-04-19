# encoding: utf-8
module Mongoid
  module Association
    module Referenced
      class BelongsTo

        # Eager class for belongs_to associations.
        class Eager < Association::Referenced::Eager::Base

          private

          def preload
            raise Errors::EagerLoad.new(@association.name) if @association.polymorphic?

            @docs.each do |d|
              set_relation(d, nil)
            end

            each_loaded_document do |doc|
              id = doc.send(key)
              set_on_parent(id, doc)
            end
          end

          def group_by_key
            @association.foreign_key
          end

          def key
            @association.primary_key
          end
        end
      end
    end
  end
end
