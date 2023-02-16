module Mongoid
  module Matcher

    # @api private
    module Exists

      # Returns whether an $exists expression is satisfied.
      #
      # @param exists [ true | false ] exists Whether the value exists.
      # @param value [ Object ] value Not used.
      # @param expr [ Array<Hash> ] condition The $exists condition.
      #
      # @return [ true | false ] Whether the existence condition is met.
      #
      # @api private
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
