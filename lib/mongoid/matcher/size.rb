module Mongoid
  module Matcher

    # @api private
    module Size
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
