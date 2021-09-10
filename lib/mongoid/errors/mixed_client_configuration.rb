# frozen_string_literal: true

module Mongoid
  module Errors

    # This error is raised when a client configuration contains both a uri and
    # other standard options.
    class MixedClientConfiguration < MongoidError

      # Initialize the error.
      #
      # @example Initialize the error.
      #   MixedClientConfiguration.new(:name, {})
      #
      # @param [ Symbol ] name The name of the client config.
      # @param [ Hash ] config The configuration options.
      def initialize(name, config)
        super(
          compose_message(
            "mixed_client_configuration",
            { name: name, config: config }
          )
        )
      end
    end
  end
end
