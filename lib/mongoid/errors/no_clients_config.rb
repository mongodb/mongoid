# encoding: utf-8
module Mongoid
  module Errors

    # This error is raised when no clients exists in the database
    # configuration.
    class NoClientsConfig < MongoidError

      # Create the new error.
      #
      # @example Create the error.
      #   NoClientsConfig.new
      #
      # @since 3.0.0
      def initialize
        super(compose_message("no_clients_config", {}))
      end
    end
  end
end
