# frozen_string_literal: true

module Mongoid
  module Errors
    # Raised when an unsupported isolation level is used in Mongoid
    # configuration.
    class UnsupportedIsolationLevel < MongoidError
      # Create the new error caused by attempting to select an unsupported
      # isolation level.
      #
      # @param [ Symbol ] level The requested isolation level.
      def initialize(level)
        super(
          compose_message(
            'unsupported_isolation_level',
            { level: level }
          )
        )
      end
    end
  end
end
