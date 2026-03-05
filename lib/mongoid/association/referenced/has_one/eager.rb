# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module Association
    module Referenced
      class HasOne
        # Eager class for has_one associations.
        class Eager < Association::Eager

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
