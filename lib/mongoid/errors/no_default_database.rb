# encoding: utf-8
module Mongoid #:nodoc
  module Errors #:nodoc

    # This error is raised when a default database is not defined.
    class NoDefaultDatabase < MongoidError

      # Create the new error with the defined database names.
      #
      # @example Create the new error.
      #   NoDefaultDatabase.new([ :secondary ])
      #
      # @param [ Array<Symbol> ] keys The defined databases.
      #
      # @since 3.0.0
      def initialize(keys)
        super(
          compose_message("no_default_database", { keys: keys.join(", ") })
        )
      end
    end
  end
end
