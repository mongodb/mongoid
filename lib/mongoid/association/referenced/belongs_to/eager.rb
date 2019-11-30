# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Association
    module Referenced
      class BelongsTo

        # Eager class for belongs_to associations.
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

          def each_loaded_document(&block)
            return super(&block) unless @association.polymorphic?

            keys_by_type_from_docs.each do |type, doc_keys|
              super(Object.const_get(type), doc_keys, &block)
            end
          end

          def keys_by_type_from_docs
            inverse_type = @association.inverse_type

            @docs.each_with_object({}) do |doc, keys_by_type|
              next unless doc.respond_to?(inverse_type) && doc.respond_to?(group_by_key)
              next if doc.send(inverse_type).nil?

              keys_by_type[doc.send(inverse_type)] ||= []
              keys_by_type[doc.send(inverse_type)].push(doc.send(group_by_key))
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
