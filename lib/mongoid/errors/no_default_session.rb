# encoding: utf-8
module Mongoid
  module Errors

    # This error is raised when a default session is not defined.
    class NoDefaultSession < MongoidError

      # Create the new error with the defined session names.
      #
      # @example Create the new error.
      #   NoDefaultSession.new([ :secondary ])
      #
      # @param [ Array<Symbol> ] keys The defined sessions.
      #
      # @since 3.0.0
      def initialize(keys)
        super(
          compose_message("no_default_session", { keys: keys.join(", ") })
        )
      end
    end
  end
end
