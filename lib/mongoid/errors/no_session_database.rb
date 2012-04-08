# encoding: utf-8
module Mongoid #:nodoc
  module Errors #:nodoc

    # This error is raised when a session is configured without a database.
    class NoSessionDatabase < MongoidError

      # Create the new error.
      #
      # @example Create the new error.
      #   NoSessionDatabase.new(:default, {}})
      #
      # @param [ Symbol, String ] name The db config key.
      # @param [ Hash ] config The hash configuration options.
      #
      # @since 3.0.0
      def initialize(name, config)
        super(
          compose_message(
            "no_session_database",
            { name: name, config: config }
          )
        )
      end
    end
  end
end
