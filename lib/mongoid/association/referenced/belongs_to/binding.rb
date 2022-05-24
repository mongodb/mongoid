# frozen_string_literal: true

module Mongoid
  module Association
    module Referenced
      class BelongsTo

        # Binding class for belongs_to associations.
        class Binding
          include Bindable

          # Binds the base object to the inverse of the association. This is so we
          # are referenced to the actual objects themselves on both sides.
          #
          # This case sets the association on the inverse object as well as the
          # document itself.
          #
          # @example Bind the documents.
          #   game.person.bind(:continue => true)
          #   game.person = Person.new
          def bind_one
            binding do
              check_polymorphic_inverses!(_target)
              bind_foreign_key(_base, record_id(_target))
              bind_polymorphic_inverse_type(_base, _target.class.name)
              if inverse = _association.inverse(_target)
                remove_associated(_target)
                if set_base_association
                  if _base.referenced_many?
                    _target.__send__(inverse).push(_base)
                  else
                    _target.set_relation(inverse, _base)
                  end
                end
              end
            end
          end

          # Unbinds the base object and the inverse, caused by setting the
          # reference to nil.
          #
          # @example Unbind the document.
          #   game.person.unbind(:continue => true)
          #   game.person = nil
          def unbind_one
            binding do
              inverse = _association.inverse(_target)
              bind_foreign_key(_base, nil)
              bind_polymorphic_inverse_type(_base, nil)
              if inverse
                set_base_association
                if _base.referenced_many?
                  _target.__send__(inverse).delete(_base)
                else
                  _target.set_relation(inverse, nil)
                end
              end
            end
          end

          private

          # Check for problems with multiple inverse definitions.
          #
          # @api private
          #
          # @example Check for inverses errors.
          #   binding.check_inverses!(doc)
          #
          # @param [ Document ] doc The document to check.
          def check_polymorphic_inverses!(doc)
            inverses = _association.inverses(doc)
            if inverses.length > 1 && _base.send(_association.foreign_key).nil?
              raise Errors::InvalidSetPolymorphicRelation.new(
                  _association.name, _base.class.name, _target.class.name
              )
            end
          end

          # Remove the associated document from the inverse's association.
          #
          # This method assumes that an inverse does exist.
          #
          # @param [ Document ] doc The document to remove.
          def remove_associated(doc)
            if _association.inverse_association.is_a?(HasOne)
              if associated = doc.send(_association.inverse)
                associated.send(_association.setter, nil)
              end
            end
          end
        end
      end
    end
  end
end
