module Mongoid
  module Associations
    module Embedded
      class EmbeddedIn

        # The Binding object for embedded_in associations.
        #
        # @since 7.0
        class Binding
          include Bindable

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
            # metadata is defined on Binding object
            # base.__metadata is the inverse_metadata
            # If the base already has __metadata, that avoids an exception being raised
            # when the inverse_metadata is attempted to be fetched.
            base.__metadata = metadata.inverse_metadata(target) unless base.__metadata
            base.parentize(target)
            binding do
              # is determined by checking base.__metadata
              # better to use the target to check if push or a setter should be used
              # for the relation
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
