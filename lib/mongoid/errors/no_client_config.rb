# frozen_string_literal: true

module Mongoid
  module Errors

    # This error is raised when attempting to create a new client that does
    # not have a named configuration.
    class NoClientConfig < MongoidError

      # Create the new error.
      #
      # @example Create the error.
      #   NoClientConfig.new(:analytics)
      #
      # @param [ String | Symbol ] name The name of the client.
      def initialize(name)
        super(compose_message("no_client_config", { name: name }))
      end
    end
  end
end
