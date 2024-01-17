# rubocop:todo all
module Mongoid
  module Matcher

    # In-memory matcher for $exists expression.
    #
    # @see https://www.mongodb.com/docs/manual/reference/operator/query/exists/
    #
    # @api private
    module Exists

      # Returns whether an $exists expression is satisfied.
      #
      # @param [ true | false ] exists Whether the value exists.
      # @param [ Object ] value Not used.
      # @param [ true | false ] condition The $exists condition predicate.
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
