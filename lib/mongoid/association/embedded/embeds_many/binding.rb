module Mongoid
  module Association
    module Embedded
      class EmbedsMany

        # Binding class for all embeds_many relations.
        #
        # @since 7.0
        class Binding
          include Bindable

          # Binds a single document with the inverse relation. Used
          # specifically when appending to the proxy.
          #
          # @example Bind one document.
          #   person.addresses.bind_one(address)
          #
          # @param [ Document ] doc The single document to bind.
          # @param [ Hash ] options The binding options.
          #
          # @option options [ true, false ] :continue Continue binding the inverse.
          # @option options [ true, false ] :binding Are we in build mode?
          #
          # @since 2.0.0.rc.1
          def bind_one(doc)
            doc.parentize(base)
            binding do
              doc.do_or_do_not(association.inverse_setter(target), base)
            end
          end

          # Unbind a single document.
          #
          # @example Unbind the document.
          #   person.addresses.unbind_one(document)
          #
          # @param [ Hash ] options The binding options.
          #
          # @option options [ true, false ] :continue Continue binding the inverse.
          # @option options [ true, false ] :binding Are we in build mode?
          #
          # @since 2.0.0.rc.1
          def unbind_one(doc)
            binding do
              doc.do_or_do_not(association.inverse_setter(target), nil)
            end
          end
        end
      end
    end
  end
end
