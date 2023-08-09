# rubocop:todo all
module Mongoid
  module Matcher

    # In-memory matcher for $size expression.
    #
    # @see https://www.mongodb.com/docs/manual/reference/operator/query/size/
    #
    # @api private
    module Size

      # Returns whether a value satisfies a $size expression.
      #
      # @param [ true | false ] exists Not used.
      # @param [ Numeric ] value The value to check.
      # @param [ Integer | Array<Object> ] condition The $size condition
      #   predicate, either a non-negative Integer or an Array to match size.
      #
      # @return [ true | false ] Whether the value matches.
      #
      # @api private
      module_function def matches?(exists, value, condition)
        case condition
        when Float
          raise Errors::InvalidQuery, "$size argument must be a non-negative integer: #{Errors::InvalidQuery.truncate_expr(condition)}"
        when Numeric
          if condition < 0
            raise Errors::InvalidQuery, "$size argument must be a non-negative integer: #{Errors::InvalidQuery.truncate_expr(condition)}"
          end
        else
          raise Errors::InvalidQuery, "$size argument must be a non-negative integer: #{Errors::InvalidQuery.truncate_expr(condition)}"
        end

        if Array === value
          value.length == condition
        else
          false
        end
      end
    end
  end
end
