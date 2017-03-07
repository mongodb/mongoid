# encoding: utf-8
module Mongoid
  module Associations
    module Referenced
      class HasMany

        # Eager class for has_many associations.
        class Eager < Associations::Referenced::Eager::Base

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
            doc.__build__(@metadata.name, element, @metadata) unless doc.blank?
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
end
