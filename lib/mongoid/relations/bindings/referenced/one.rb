# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Bindings #:nodoc:
      module Referenced #:nodoc:
        class One < Binding

          # Binds the base object to the inverse of the relation. This is so we
          # are referenced to the actual objects themselves and dont hit the
          # database twice when setting the relations up.
          #
          # This essentially sets the foreign key and the object itself.
          #
          # @example Bind the relation.
          #   person.game.bind
          def bind
            if bindable?
              target.send(metadata.foreign_key_setter, base.id)
              target.send(metadata.inverse_setter, base)
            end
          end

          # Unbinds the base object to the inverse of the relation. This occurs
          # when setting a side of the relation to nil.
          #
          # @example Unbind the relation.
          #   person.game.unbind
          def unbind
            if unbindable?
              target.send(metadata.foreign_key_setter, nil)
              target.send(metadata.inverse_setter, nil)
            end
          end

          private

          # Protection from infinite loops setting the inverse relations.
          # Checks if this document is not already equal to the target of the
          # inverse.
          #
          # @example Is the relation bindable?
          #   binding.bindable?
          #
          # @return [ Boolean ] True if the documents differ, false if not.
          def bindable?
            !base.equal?(inverse ? inverse.target : nil)
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
