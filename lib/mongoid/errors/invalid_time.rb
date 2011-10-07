# encoding: utf-8
module Mongoid #:nodoc
  module Errors #:nodoc

    # This exception is raised when a bad value is attempted to be converted to
    # a date or time.
    class InvalidTime < MongoidError

      attr_reader :klass, :value

      # Create the new invalid date error.
      #
      # @example Create the new invalid date error.
      #   InvalidTime.new("this is not a time")
      #
      # @param [ Object ] value The value that was attempted.
      #
      # @since 2.3.1
      def initialize(value)
        @value = value
        super(translate("invalid_time", { :value => value }))
      end
    end
  end
end
