# frozen_string_literal: true

module Mongoid
  module Errors

    # This error is raised when a client is configured without a database.
    class NoClientDatabase < MongoidError

      # Create the new error.
      #
      # @example Create the new error.
      #   NoClientDatabase.new(:default, {}})
      #
      # @param [ Symbol | String ] name The db config key.
      # @param [ Hash ] config The hash configuration options.
      def initialize(name, config)
        super(
          compose_message(
            "no_client_database",
            { name: name, config: config }
          )
        )
      end
    end
  end
end
