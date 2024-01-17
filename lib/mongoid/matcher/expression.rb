# rubocop:todo all
module Mongoid
  module Matcher

    # Base singleton module used for evaluating whether a given
    # document in-memory matches an MSQL query expression.
    #
    # @api private
    module Expression

      # Returns whether a document satisfies a query expression.
      #
      # @param [ Mongoid::Document ] document The document.
      # @param [ Hash ] expr The expression.
      #
      # @return [ true | false ] Whether the document matches.
      #
      # @api private
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
