# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module Errors

    # This error is raised when automatic encryption configuration for a client
    # is invalid.
    class InvalidAutoEncryptionConfiguration < MongoidError

      # Initialize the error.
      #
      # @param [ Symbol ] name The name of the client config.
      def initialize(name, kms_provider = nil)
        if kms_provider
          super(
            compose_message(
              "invalid_auto_encryption_configuration_for_kms_provider",
              { client: name, kms_provider: kms_provider }
            )
          )
        else
          super(
            compose_message(
              "invalid_auto_encryption_configuration",
              { client: name }
            )
          )
        end
      end
    end
  end
end
