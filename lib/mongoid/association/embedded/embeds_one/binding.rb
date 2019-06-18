# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Association
    module Embedded
      class EmbedsOne

        # Binding class for all embeds_one associations.
        #
        # @since 7.0
        class Binding
          include Bindable

          # Binds the base object to the inverse of the association. This is so we
          # are referenced to the actual objects themselves on both sides.
          #
          # This case sets the association metadata on the inverse object as well as the
          # document itself.
          #
          # @example Bind the document.
          #   person.name.bind(:continue => true)
          #   person.name = Name.new
          #
          # @since 2.0.0.rc.1
          def bind_one
            _target.parentize(_base)
            binding do
              _target.do_or_do_not(_association.inverse_setter(_target), _base)
            end
          end

          # Unbinds the base object and the inverse, caused by setting the
          # reference to nil.
          #
          # @example Unbind the document.
          #   person.name.unbind(:continue => true)
          #   person.name = nil
          #
          # @since 2.0.0.rc.1
          def unbind_one
            binding do
              _target.do_or_do_not(_association.inverse_setter(_target), nil)
            end
          end
        end
      end
    end
  end
end
