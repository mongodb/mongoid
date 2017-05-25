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
          #
          # @since 2.0.0.rc.1
          def bind_one(doc)
            doc.parentize(base)
            binding do
              doc.do_or_do_not(metadata.inverse_setter(target), base)
            end
          end

          # Unbind a single document.
          #
          # @example Unbind the document.
          #   person.addresses.unbind_one(document)
          #
          # @param [ Document ] doc The single document to unbind.
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
