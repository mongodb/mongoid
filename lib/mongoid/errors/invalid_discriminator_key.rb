# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Errors

    # This error is raised when trying to create a global discriminator key that 
    # conflicts with an already defined method.
    class InvalidDiscriminatorKey < MongoidError

      # Create the new error.
      #
      # @example Create the error.
      #   InvalidDiscriminatorKey.new(:invalid)
      #
      # @param [ Symbol ] name The method name.
      def initialize(name)
        super(
          compose_message(
            "invalid_discriminator_key",
            {
              name: name
            }
          )
        )
      end
    end
  end
end
