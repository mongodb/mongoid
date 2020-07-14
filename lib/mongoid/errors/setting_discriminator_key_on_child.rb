# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Errors

    # This error is raised when trying to create a scope with an name already
    # taken by another scope or method
    #
    # @example Create the error.
    #   ScopeOverwrite.new(Person,'teenies')
    class SettingDiscriminatorKeyOnChild < MongoidError
      def initialize(class_name, superclass)
        super(
          compose_message(
            "setting_discriminator_key_on_child",
            { class_name: class_name,  superclass: superclass}
          )
        )
      end
    end
  end
end
