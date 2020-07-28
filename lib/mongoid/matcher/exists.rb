module Mongoid
  module Matcher

    # @api private
    module Exists
      module_function def matches?(exists, value, condition)
        case condition
        when Range
          raise Errors::InvalidQuery, "$exists argument cannot be a Range: #{Errors::InvalidQuery.truncate_expr(condition)}"
        end
        exists == (condition || false)
      end
    end
  end
end
