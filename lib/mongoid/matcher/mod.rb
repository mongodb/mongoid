# rubocop:todo all
module Mongoid
  module Matcher

    # In-memory matcher for $mod expression.
    #
    # @see https://www.mongodb.com/docs/manual/reference/operator/query/mod/
    #
    # @api private
    module Mod

      # Returns whether a value satisfies a $mod expression.
      #
      # @param [ true | false ] exists Not used.
      # @param [ Numeric ] value The value to check.
      # @param [ Array<Numeric> ] condition The $mod condition predicate,
      #   which is a 2-tuple containing the divisor and remainder.
      #
      # @return [ true | false ] Whether the value matches.
      #
      # @api private
      module_function def matches?(exists, value, condition)
        unless Array === condition
          raise Errors::InvalidQuery, "Unknown $mod argument #{condition}"
        end
        if condition.length != 2
          raise Errors::InvalidQuery, "Malformed $mod argument #{condition}, should have 2 elements"
        end
        condition[1] == value%condition[0]
      end
    end
  end
end
