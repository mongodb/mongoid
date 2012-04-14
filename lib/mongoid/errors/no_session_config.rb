# encoding: utf-8
module Mongoid
  module Errors

    # This error is raised when attempting to create a new session that does
    # not have a named configuration.
    class NoSessionConfig < MongoidError

      # Create the new error.
      #
      # @example Create the error.
      #   NoSessionConfig.new(:secondary)
      #
      # @param [ String, Symbol ] name The name of the session.
      #
      # @since 3.0.0
      def initialize(name)
        super(compose_message("no_session_config", { name: name }))
      end
    end
  end
end
