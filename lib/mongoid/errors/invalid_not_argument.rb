# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Errors

    # Raised when something other than a hash is passed as an argument
    # to $not.
    class InvalidNotArgument < MongoidError

      # Create the new exception.
      #
      # @since 7.1.0
      def initialize(argument)
        super(compose_message("invalid_not_argument", {argument: argument}))
      end
    end
  end
end
