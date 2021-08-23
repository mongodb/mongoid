# frozen_string_literal: true

module Mongoid
  module Association
    module Referenced
      class HasMany

        # Eager class for has_many associations.
        class Eager < Association::Referenced::Eager::Base

          private

          def preload
            @docs.each do |d|
              set_relation(d, [])
            end

            entries = Hash.new { |hash, key| hash[key] = [] }
            each_loaded_document do |doc|
              fk = doc.send(key)
              entries[fk] << doc
            end

            entries.each do |id, docs|
              set_on_parent(id, docs)
            end
          end

          def set_relation(doc, element)
            doc.__build__(@association.name, element, @association) unless doc.blank?
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
