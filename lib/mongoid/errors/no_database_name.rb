# encoding: utf-8
module Mongoid #:nodoc
  module Errors #:nodoc

    # This error is raised when a database is configured without a name.
    class NoDatabaseName < MongoidError

      # Create the new error.
      #
      # @example Create the new error.
      #   NoDatabaseName.new(:default, { session: :default }})
      #
      # @param [ Symbol, String ] name The db config key.
      # @param [ Hash ] config The hash configuration options.
      #
      # @since 3.0.0
      def initialize(name, config)
        super(
          compose_message(
            "no_database_name",
            { name: name, config: config }
          )
        )
      end
    end
  end
end
