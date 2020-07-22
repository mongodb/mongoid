# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Errors

    # Creates the exception raised when trying to set or get the 
    # discriminator mapping on a parent class.
    #
    # @param [ String ] class_name The class name.
    #
    # @api private
    class InvalidDiscriminatorMappingTarget < MongoidError
      def initialize(class_name)
        super(
          compose_message(
            "invalid_discriminator_mapping_target",
            { class_name: class_name }
          )
        )
      end
    end
  end
end
