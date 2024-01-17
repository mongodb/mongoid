# rubocop:todo all
module Mongoid
  module Matcher

    # In-memory matcher for $in expression.
    #
    # @see https://www.mongodb.com/docs/manual/reference/operator/query/in/
    #
    # @api private
    module In

      # Returns whether a value satisfies an $in expression.
      #
      # @param [ true | false ] exists Not used.
      # @param [ Object ] value The value to check.
      # @param [ Array<Object> ] condition The $in condition predicate.
      #
      # @return [ true | false ] Whether the value matches.
      #
      # @api private
      module_function def matches?(exists, value, condition)
        unless Array === condition
          raise Errors::InvalidQuery, "$in argument must be an array: #{Errors::InvalidQuery.truncate_expr(condition)}"
        end
        if Array === value
          if value.any? { |v|
            condition.any? do |c|
              EqImplWithRegexp.matches?('$in', v, c)
            end
          } then
            return true
          end
        end
        condition.any? do |c|
          EqImplWithRegexp.matches?('$in', value, c)
        end
      end
    end
  end
end
