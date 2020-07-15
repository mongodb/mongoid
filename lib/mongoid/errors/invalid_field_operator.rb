# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Errors

    # Raised when invalid field-level operator is passed to an
    # embedded matcher.
    class InvalidFieldOperator < InvalidQuery

      # @api private
      VALID_OPERATORS = %w(
        all elemMatch eq exists gt gte in lt lte ne nin not regex size
      ).freeze

      # Creates the exception.
      #
      # @param [ String ] operator The operator that was used.
      #
      # @api private
      def initialize(operator)
        super(compose_message("invalid_field_operator",
          operator: operator,
          valid_operators: VALID_OPERATORS.map { |op| "'$#{op}'" }.join(', '),
        ))
      end
    end
  end
end
