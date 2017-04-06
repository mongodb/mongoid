# encoding: utf-8
module Mongoid
  module Association
    module Referenced
      class BelongsTo

        # Binding class for belongs_to associations.
        class Binding
          include Bindable

          # Binds the base object to the inverse of the relation. This is so we
          # are referenced to the actual objects themselves on both sides.
          #
          # This case sets the association on the inverse object as well as the
          # document itself.
          #
          # @example Bind the documents.
          #   game.person.bind(:continue => true)
          #   game.person = Person.new
          #
          # @since 2.0.0.rc.1
          def bind_one
            binding do
              check_polymorphic_inverses!(target)
              bind_foreign_key(base, record_id(target))
              bind_polymorphic_inverse_type(base, target.class.name)
              if inverse = association.inverse(target)
                if set_base_association
                  if base.referenced_many?
                    target.__send__(inverse).push(base)
                  else
                    target.set_relation(inverse, base)
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
          #
          # @since 2.0.0.rc.1
          def unbind_one
            binding do
              inverse = association.inverse(target)
              bind_foreign_key(base, nil)
              bind_polymorphic_inverse_type(base, nil)
              if inverse
                set_base_association
                if base.referenced_many?
                  target.__send__(inverse).delete(base)
                else
                  target.set_relation(inverse, nil)
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
          #
          # @since 3.0.0
          def check_polymorphic_inverses!(doc)
            inverses = association.inverses(doc)
            if inverses.count > 1 && base.send(association.foreign_key).nil?
              raise Errors::InvalidSetPolymorphicRelation.new(
                  association.name, base.class.name, target.class.name
              )
            end
          end
        end
      end
    end
  end
end
