# frozen_string_literal: true

module Mongoid
  module Association
    module Referenced
      class HasAndBelongsToMany

        # Binding class for all has_and_belongs_to_many associations.
        class Binding
          include Bindable

          # Binds a single document with the inverse association. Used
          # specifically when appending to the proxy.
          #
          # @example Bind one document.
          #   person.preferences.bind_one(preference)
          #
          # @param [ Document ] doc The single document to bind.
          def bind_one(doc)
            binding do
              inverse_keys = doc.you_must(_association.inverse_foreign_key)
              if inverse_keys
                record_id = inverse_record_id(doc)
                unless inverse_keys.include?(record_id)
                  doc.you_must(_association.inverse_foreign_key_setter, inverse_keys.push(record_id))
                end
                doc.reset_relation_criteria(_association.inverse)
              end
              _base._synced[_association.foreign_key] = true
              doc._synced[_association.inverse_foreign_key] = true
            end
          end

          # Unbind a single document.
          #
          # @example Unbind the document.
          #   person.preferences.unbind_one(document)
          def unbind_one(doc)
            binding do
              _base.send(_association.foreign_key).delete_one(record_id(doc))
              inverse_keys = doc.you_must(_association.inverse_foreign_key)
              if inverse_keys
                inverse_keys.delete_one(inverse_record_id(doc))
                doc.reset_relation_criteria(_association.inverse)
              end
              _base._synced[_association.foreign_key] = true
              doc._synced[_association.inverse_foreign_key] = true
            end
          end

          # Find the inverse id referenced by inverse_keys
          def inverse_record_id(doc)
            if pk = _association.options[:inverse_primary_key]
              _base.send(pk)
            else
              inverse_association = determine_inverse_association(doc)
              if inverse_association
                _base.__send__(inverse_association.primary_key)
              else
                _base._id
              end
            end
          end

          def determine_inverse_association(doc)
            doc.relations[_base.class.name.demodulize.underscore.pluralize]
          end
        end
      end
    end
  end
end
