module Mongoid
  module Matcher

    # @api private
    module ExpressionOperator
      MAP = {
        '$and' => And,
        '$nor' => Nor,
        '$or' => Or,
      }.freeze

      module_function def get(op)
        MAP.fetch(op)
      rescue KeyError
        raise Errors::InvalidExpressionOperator.new(op)
      end
    end
  end
end
