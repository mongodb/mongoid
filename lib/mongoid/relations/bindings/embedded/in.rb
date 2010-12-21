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
          # @example Bind the documents.
          #   name.person.bind
          #   name.person = Person.new
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
          # @example Unbind the documents.
          #   name.person.unbind
          #   name.person = nil
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
          # @example Is the relation bindable?
          #   binding.bindable?
          #
          # @return [ Boolean ] True if the documents differ, false if not.
          def bindable?
            if base.embedded_many?
              inverse && !inverse.target.include?(base)
            else
              !base.equal?(inverse ? inverse.target : nil)
            end
          end

          # Protection from infinite loops removing the inverse relations.
          # Checks if the target of the inverse is not already nil.
          #
          # @example Is the relation unbindable?
          #   binding.unbindable?
          #
          # @return [ Boolean ] True if the target is not nil, false if not.
          def unbindable?
            !target.send(metadata.inverse(target)).nil?
          end
        end
      end
    end
  end
end
