# frozen_string_literal: true

module Mongoid
  module Errors
    # Raised when transaction is called from inside a changeset block.
    class TransactionInChangeset < MongoidError
      def initialize
        super(compose_message('transaction_in_changeset'))
      end
    end
  end
end
