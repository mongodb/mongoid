# frozen_string_literal: true
# encoding: utf-8

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
        super(compose_message("invalid_expression_operator",
          operator: operator,
          valid_operators: "'$and', '$nor', '$or'",
        ))
      end
    end
  end
end
