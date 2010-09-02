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
          # <tt>game.person.bind</tt>
          def bind
            # if embedded_bindable?(base)
              # inverse = metadata.inverse(target)
              # base.metadata =
                # target.class.reflect_on_association(inverse)
              # target.send(metadata.inverse_setter(target), base)
            # end
          end

          def unbind
            # if embedded_unbindable?(base)
              # target.send(metadata.inverse_setter(target), nil)
            # end
          end
        end
      end
    end
  end
end
