module Mongoid
  module Matcher

    # @api private
    module Expression
      module_function def matches?(document, expr)
        if expr.nil?
          raise Errors::InvalidQuery, "Nil condition in expression context"
        end
        unless Hash === expr
          raise Errors::InvalidQuery, "MQL query must be provided as a Hash"
        end
        expr.all? do |k, expr_v|
          k = k.to_s
          if k == "$comment"
            # Nothing
            return true
          end
          if k.start_with?('$')
            ExpressionOperator.get(k).matches?(document, expr_v)
          else
            values = Matcher.extract_attribute(document, k)
            if values.length > 0
              values.any? do |v|
                FieldExpression.matches?(true, v, expr_v)
              end
            else
              FieldExpression.matches?(false, nil, expr_v)
            end
          end
        end
      end
    end
  end
end
