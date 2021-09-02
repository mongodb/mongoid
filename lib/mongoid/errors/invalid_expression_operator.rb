# frozen_string_literal: true

module Mongoid
  module Errors

    # Raised when invalid expression-level operator is passed to an
    # embedded matcher.
    class InvalidExpressionOperator < InvalidQuery

      # Creates the exception.
      #
      # @param [ String ] operator The operator that was used.
      #
      # @api private
      def initialize(operator)
        @operator = operator
        super(compose_message("invalid_expression_operator",
          operator: operator,
          valid_operators: "'$and', '$nor', '$or'",
        ))
      end

      # @return [ String ] The operator that was used.
      attr_reader :operator
    end
  end
end
