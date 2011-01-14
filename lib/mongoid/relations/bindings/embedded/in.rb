# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Bindings #:nodoc:
      module Embedded #:nodoc:

        # Binding class for embedded_in relations.
        class In < Binding

          # Binds the base object to the inverse of the relation. This is so we
          # are referenced to the actual objects themselves on both sides.
          #
          # This case sets the metadata on the inverse object as well as the
          # document itself.
          #
          # @example Bind the documents.
          #   name.person.bind(:continue => true)
          #   name.person = Person.new
          #
          # @param [ Hash ] options The binding options.
          #
          # @option options [ true, false ] :continue Continue binding the inverse.
          # @option options [ true, false ] :binding Are we in build mode?
          #
          # @since 2.0.0.rc.1
          def bind(options = {})
            inverse = metadata.inverse(target)
            base.metadata = target.reflect_on_association(inverse)
            base.parentize(target)
            if options[:continue]
              if base.embedded_many?
                target.do_or_do_not(
                  inverse,
                  false,
                  :binding => true,
                  :continue => false
                ).push(base, :binding => true, :continue => false)
              else
                target.do_or_do_not(
                  metadata.inverse_setter(target),
                  base,
                  :binding => true,
                  :continue => false
                )
              end
            end
          end
          alias :bind_one :bind

          # Unbinds the base object and the inverse, caused by setting the
          # reference to nil.
          #
          # @example Unbind the document.
          #   name.person.unbind(:continue => true)
          #   name.person = nil
          #
          # @param [ Hash ] options The options to pass through.
          #
          # @option options [ true, false ] :continue Do we continue unbinding?
          #
          # @since 2.0.0.rc.1
          def unbind(options = {})
            if options[:continue]
              if base.embedded_many?
                inverse = metadata.inverse(target)
                target.do_or_do_not(inverse).delete(base)
              else
                target.do_or_do_not(
                  metadata.inverse_setter(target),
                  nil,
                  :binding => true,
                  :continue => false
                )
              end
            end
          end
          alias :unbind_one :unbind
        end
      end
    end
  end
end
