# frozen_string_literal: true

module Mongoid
  module Association
    module Referenced

      class HasOne

        class Eager < Association::Referenced::Eager::Base

          private

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
            @association.primary_key
          end

          def key
            @association.foreign_key
          end

        end
      end
    end
  end
end
