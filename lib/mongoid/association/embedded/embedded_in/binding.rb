# frozen_string_literal: true

module Mongoid
  module Association
    module Embedded
      class EmbeddedIn

        # The Binding object for embedded_in associations.
        class Binding
          include Bindable

          # Binds the base object to the inverse of the association. This is so we
          # are referenced to the actual objects themselves on both sides.
          #
          # This case sets the association metadata on the inverse object as well as the
          # document itself.
          #
          # @example Bind the documents.
          #   name.person.bind(:continue => true)
          #   name.person = Person.new
          def bind_one
            binding do
              check_polymorphic_inverses!(_target)
              _base._association = _association.inverse_association(_target) unless _base._association
              _base.parentize(_target)
              if _base.embedded_many?
                _target.do_or_do_not(_association.inverse(_target)).push(_base)
              else
                remove_associated(_target)
                _target.do_or_do_not(_association.inverse_setter(_target), _base)
              end
            end
          end

          # Unbinds the base object and the inverse, caused by setting the
          # reference to nil.
          #
          # @example Unbind the document.
          #   name.person.unbind(:continue => true)
          #   name.person = nil
          def unbind_one
            binding do
              if _base.embedded_many?
                _target.do_or_do_not(_association.inverse(_target)).delete(_base)
              else
                _target.do_or_do_not(_association.inverse_setter(_target), nil)
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
            if inverses = _association.inverses(doc)
              if inverses.length > 1
                raise Errors::InvalidSetPolymorphicRelation.new(
                    _association.name, _base.class.name, _target.class.name
                )
              end
            end
          end
        end
      end
    end
  end
end
