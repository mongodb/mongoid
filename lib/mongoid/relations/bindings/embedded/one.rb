# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Bindings #:nodoc:
      module Embedded #:nodoc:
        class One < Binding

          # Binds the base object to the inverse of the relation. This is so we
          # are referenced to the actual objects themselves on both sides.
          #
          # This case sets the metadata on the inverse object as well as the
          # document itself.
          #
          # Example:
          #
          # <tt>person.name.bind</tt>
          # <tt>person.name = Name.new</tt>
          def bind
            target.send(metadata.inverse_setter(target), base) if bindable?
          end

          # Unbinds the base object and the inverse, caused by setting the
          # reference to nil.
          #
          # Example:
          #
          # <tt>person.name.unbind</tt>
          # <tt>person.name = nil</tt>
          def unbind
            target.send(metadata.inverse_setter(target), nil) if unbindable?
          end

          private

          # Determine what the inverse of this relation is.
          #
          # Example:
          #
          # <tt>binding.inverse</tt>
          #
          # Returns:
          #
          # The inverse of this relation.
          def inverse
            target ? target.send(metadata.inverse(target)) : nil
          end

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
