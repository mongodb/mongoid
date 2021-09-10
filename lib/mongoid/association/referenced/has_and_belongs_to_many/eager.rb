# frozen_string_literal: true

module Mongoid
  module Association
    module Referenced
      class HasAndBelongsToMany

        # Eager class for has_and_belongs_to_many associations.
        class Eager < Association::Referenced::Eager::Base

          private

          def preload
            @docs.each do |d|
              set_relation(d, [])
            end

            entries = {}
            each_loaded_document do |doc|
              entries[doc.send(key)] = doc
            end

            @docs.each do |d|
              keys = d.send(group_by_key)
              docs = entries.values_at(*keys).compact
              set_relation(d, docs)
            end
          end

          def keys_from_docs
            keys = Set.new
            @docs.each do |d|
              keys += d.send(group_by_key)
            end
            keys.to_a
          end

          def set_relation(doc, element)
            doc.__build__(@association.name, element, @association) unless doc.blank?
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
