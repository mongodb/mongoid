# encoding: utf-8
module Mongoid
  module Associations
    module Referenced
      class BelongsTo

        # Eager class for belongs_to associations.
        class Eager < Associations::Referenced::Eager::Base

          private

          def preload
            raise Errors::EagerLoad.new(@metadata.name) if @metadata.polymorphic?

            @docs.each do |d|
              set_relation(d, nil)
            end

            each_loaded_document do |doc|
              id = doc.send(key)
              set_on_parent(id, doc)
            end
          end

          def group_by_key
            @metadata.foreign_key
          end

          def key
            @metadata.primary_key
          end
        end
      end
    end
  end
end
