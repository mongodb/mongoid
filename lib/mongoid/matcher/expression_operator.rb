# rubocop:todo all
module Mongoid
  module Matcher

    # Singleton module provides lookup of logical query operator
    # matchers.
    #
    # @api private
    module ExpressionOperator
      MAP = {
        '$and' => And,
        '$nor' => Nor,
        '$or' => Or,
      }.freeze

      # Returns the matcher module for a given operator.
      #
      # @param [ String ] op The operator name.
      #
      # @return [ Module ] The matcher module.
      #
      # @raises [ Mongoid::Errors::InvalidExpressionOperator ]
      #   Raised if the given operator is unknown.
      #
      # @api private
      module_function def get(op)
        MAP.fetch(op)
      rescue KeyError
        raise Errors::InvalidExpressionOperator.new(op)
      end
    end
  end
end
