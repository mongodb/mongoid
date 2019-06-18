# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Association
    module Embedded
      class EmbedsMany

        # Binding class for all embeds_many associations.
        #
        # @since 7.0
        class Binding
          include Bindable

          # Binds a single document with the inverse association. Used
          # specifically when appending to the proxy.
          #
          # @example Bind one document.
          #   person.addresses.bind_one(address)
          #
          # @param [ Document ] doc The single document to bind.
          #
          # @since 2.0.0.rc.1
          def bind_one(doc)
            doc.parentize(_base)
            binding do
              doc.do_or_do_not(_association.inverse_setter(_target), _base)
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
              doc.do_or_do_not(_association.inverse_setter(_target), nil)
            end
          end
        end
      end
    end
  end
end
