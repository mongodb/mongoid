# encoding: utf-8
module Mongoid
  module Errors

    # This error is raised when attempting to create a new client that does
    # not have a named configuration.
    class NoClientConfig < MongoidError

      # Create the new error.
      #
      # @example Create the error.
      #   NoClientConfig.new(:secondary)
      #
      # @param [ String, Symbol ] name The name of the client.
      #
      # @since 3.0.0
      def initialize(name)
        super(compose_message("no_client_config", { name: name }))
      end
    end
  end
end
