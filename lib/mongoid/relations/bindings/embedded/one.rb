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
          # @example Bind the document.
          #   person.name.bind
          #   person.name = Name.new
          def bind
            target.send(metadata.inverse_setter(target), base) if bindable?
          end

          # Unbinds the base object and the inverse, caused by setting the
          # reference to nil.
          #
          # @example Unbind the document.
          #   person.name.unbind
          #   person.name = nil
          def unbind
            target.send(metadata.inverse_setter(target), nil) if unbindable?
          end

          private

          # Determine what the inverse of this relation is.
          #
          # @example Get the inverse.
          #   binding.inverse
          #
          # @return [ Proxy ] The inverse of this relation.
          def inverse
            target ? target.send(metadata.inverse(target)) : nil
          end

          # Protection from infinite loops setting the inverse relations.
          # Checks if this document is not already equal to the target of the
          # inverse.
          #
          # @example Is this relation bindable?
          #   binding.bindable?
          #
          # @return [ true, false ] True if the documents differ, false if not.
          def bindable?
            !base.equal?(inverse ? inverse.target : nil)
          end

          # Protection from infinite loops removing the inverse relations.
          # Checks if the target of the inverse is not already nil.
          #
          # @example Is the relation unbindable?
          #   binding.unbindable?
          #
          # @return [ true, false ] True if the target is not nil, false if not.
          def unbindable?
            !target.send(metadata.inverse(target)).nil?
          end
        end
      end
    end
  end
end
