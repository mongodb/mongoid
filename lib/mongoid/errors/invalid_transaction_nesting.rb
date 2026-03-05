# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module Errors

    # This error is raised when a transaction is attempted to be used with a model whose client already
    # has an opened transaction.
    class InvalidTransactionNesting < MongoidError

      # Create the error.
      def initialize
        super(compose_message('invalid_transaction_nesting'))
      end
    end
  end
end
