# frozen_string_literal: true

module Mongoid
  module Errors

    # This error is raised when no clients exists in the database
    # configuration.
    class NoClientsConfig < MongoidError

      # Create the new error.
      #
      # @example Create the error.
      #   NoClientsConfig.new
      def initialize
        super(compose_message("no_clients_config", {}))
      end
    end
  end
end
