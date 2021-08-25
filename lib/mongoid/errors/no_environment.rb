# frozen_string_literal: true

module Mongoid
  module Errors

    # Raised when trying to load configuration with no RACK_ENV set
    class NoEnvironment < MongoidError

      # Create the new no environment error.
      #
      # @example Create the new no environment error.
      #   NoEnvironment.new
      def initialize
        super(compose_message("no_environment", {}))
      end
    end
  end
end
