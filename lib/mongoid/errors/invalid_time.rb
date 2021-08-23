# frozen_string_literal: true

module Mongoid
  module Errors

    # This exception is raised when a bad value is attempted to be converted to
    # a date or time.
    class InvalidTime < MongoidError

      # Create the new invalid date error.
      #
      # @example Create the new invalid date error.
      #   InvalidTime.new("this is not a time")
      #
      # @param [ Object ] value The value that was attempted.
      def initialize(value)
        super(compose_message("invalid_time", { value: value }))
      end
    end
  end
end
