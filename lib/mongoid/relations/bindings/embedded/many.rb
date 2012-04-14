# encoding: utf-8
module Mongoid
  module Relations
    module Bindings
      module Embedded

        # Binding class for embeds_many relations.
        class Many < Binding

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
              unless metadata.versioned?
                doc.do_or_do_not(metadata.inverse_setter(target), base)
              end
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
              doc.do_or_do_not(metadata.inverse_setter(target), nil)
            end
          end
        end
      end
    end
  end
end
