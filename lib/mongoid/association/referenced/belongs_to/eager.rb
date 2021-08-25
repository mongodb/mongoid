# frozen_string_literal: true

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

          # Retrieves the documents referenced by the association, and
          # yields each one sequentially to the provided block. If the
          # association is not polymorphic, all documents are retrieved in
          # a single query. If the association is polymorphic, one query is
          # issued per association target class.
          def each_loaded_document(&block)
            if @association.polymorphic?
              keys_by_type_from_docs.each do |type, keys|
                each_loaded_document_of_class(Object.const_get(type), keys, &block)
              end
            else
              super
            end
          end

          # Returns a map from association target class name to foreign key
          # values for the documents of that association target class,
          # as referenced by this association.
          def keys_by_type_from_docs
            inverse_type_field = @association.inverse_type

            @docs.each_with_object({}) do |doc, keys_by_type|
              next unless doc.respond_to?(inverse_type_field) && doc.respond_to?(group_by_key)
              inverse_type_name = doc.send(inverse_type_field)
              # If a particular document does not have a value for this
              # association, inverse_type_name will be nil.
              next if inverse_type_name.nil?

              key_value = doc.send(group_by_key)
              # If a document has the *_type field set but the corresponding
              # *_id field not set, the key value here will be nil.
              next unless key_value

              keys_by_type[inverse_type_name] ||= []
              keys_by_type[inverse_type_name].push(key_value)
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
