# encoding: utf-8
module Mongoid
  module Relations
    module Bindings
      module Embedded

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
          def bind_one
            base.metadata = metadata.inverse_metadata(target) unless base.metadata
            base.parentize(target)
            binding do
              if base.embedded_many?
                target.do_or_do_not(metadata.inverse(target)).push(base)
              else
                target.do_or_do_not(metadata.inverse_setter(target), base)
              end
            end
          end

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
          def unbind_one
            binding do
              if base.embedded_many?
                target.do_or_do_not(metadata.inverse(target)).delete(base)
              else
                target.do_or_do_not(metadata.inverse_setter(target), nil)
              end
            end
          end
        end
      end
    end
  end
end
