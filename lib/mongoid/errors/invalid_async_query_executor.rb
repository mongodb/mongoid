# frozen_string_literal: true

module Mongoid
  module Errors

    # This error is raised when a bad async query executor option is attempted
    # to be set.
    class InvalidQueryExecutor < MongoidError

      # Create the new error.
      #
      # @param [ Symbol | String ] executor The attempted async query executor.
      #
      # @api private
      def initialize(executor)
        super(
          compose_message(
            "invalid_async_query_executor",
            { executor: executor, options: [:immediate, :global_thread_pool] }
          )
        )
      end
    end
  end
end
