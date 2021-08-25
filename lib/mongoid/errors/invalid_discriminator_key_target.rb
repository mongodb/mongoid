# frozen_string_literal: true

module Mongoid
  module Errors

    # Creates the exception raised when trying to set or get the 
    # discriminator key on a child class.
    #
    # @param [ String ] class_name The class name.
    # @param [ String ] operator The class' superclass.
    #
    # @api private
    class InvalidDiscriminatorKeyTarget < MongoidError
      def initialize(class_name, superclass)
        super(
          compose_message(
            "invalid_discriminator_key_target",
            { class_name: class_name, superclass: superclass }
          )
        )
      end
    end
  end
end
