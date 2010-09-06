# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Bindings #:nodoc:
      module Embedded #:nodoc:
        class In < Binding

          # Binds the base object to the inverse of the relation. This is so we
          # are referenced to the actual objects themselves on both sides.
          #
          # This case sets the metadata on the inverse object as well as the
          # document itself.
          #
          # Example:
          #
          # <tt>name.person.bind</tt>
          # <tt>name.person = Person.new</tt>
          def bind
            if bindable?
              inverse = metadata.inverse(target)
              base.metadata = target.reflect_on_association(inverse)
              if base.embedded_many?
                target.send(inverse).push(base)
              else
                target.send(metadata.inverse_setter(target), base)
              end
            end
          end

          # Unbinds the base object and the inverse, caused by setting the
          # reference to nil.
          #
          # Example:
          #
          # <tt>name.person.unbind</tt>
          # <tt>name.person = nil</tt>
          def unbind
            if unbindable?
              if base.embedded_many?
                inverse = metadata.inverse(target)
                target.send(inverse).delete(base)
              else
                target.send(metadata.inverse_setter(target), nil)
              end
            end
          end

          private

          # Protection from infinite loops setting the inverse relations.
          # Checks if this document is not already equal to the target of the
          # inverse.
          #
          # Example:
          #
          # <tt>binding.bindable?</tt>
          #
          # Returns:
          #
          # true if the documents differ, false if not.
          def bindable?
            !base.equal?(inverse ? inverse.target : nil)
          end

          # Protection from infinite loops removing the inverse relations.
          # Checks if the target of the inverse is not already nil.
          #
          # Example:
          #
          # <tt>binding.unbindable?</tt>
          #
          # Returns:
          #
          # true if the target is not nil, false if not.
          def unbindable?
            !target.send(metadata.inverse(target)).nil?
          end
        end
      end
    end
  end
end
