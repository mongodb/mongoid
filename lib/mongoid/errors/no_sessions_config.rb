# encoding: utf-8
module Mongoid
  module Errors

    # This error is raised when no sessions exists in the database
    # configuration.
    class NoSessionsConfig < MongoidError

      # Create the new error.
      #
      # @example Create the error.
      #   NoSessionsConfig.new
      #
      # @since 3.0.0
      def initialize
        super(compose_message("no_sessions_config", {}))
      end
    end
  end
end
