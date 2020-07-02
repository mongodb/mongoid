module Mongoid
  module Matcher

    # $elemMatch argument can be a top-level expression or a field expression.
    #
    # @api private
    module ElemMatchExpression
      module_function def matches?(document, expr)
        Expression.matches?(document, expr) ||
          FieldExpression.matches?(true, document, expr)
      rescue Errors::InvalidExpressionOperator
        FieldExpression.matches?(true, document, expr)
      end
    end
  end
end
