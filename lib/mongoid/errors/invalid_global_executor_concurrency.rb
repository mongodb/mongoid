# frozen_string_literal: true

module Mongoid
  module Errors

    # This error is raised when a bad global executor concurrency option is attempted
    # to be set.
    class InvalidGlobalExecutorConcurrency < MongoidError

      # Create the new error.
      #
      # @api private
      def initialize
        super(
          compose_message(
            "invalid_global_executor_concurrency"
          )
        )
      end
    end
  end
end
