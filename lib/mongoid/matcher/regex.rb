module Mongoid
  module Matcher
    # In-memory matcher for $regex expression.
    #
    # @see https://www.mongodb.com/docs/manual/reference/operator/query/regex/
    #
    # @api private
    module Regex
      # Returns whether a value satisfies a $regex expression.
      #
      # @param [ true | false ] exists Not used.
      # @param [ String | Array<String> ] value The value to check.
      # @param [ Regexp | BSON::Regexp::Raw ] condition The $regex condition.
      #
      # @return [ true | false ] Whether the value matches.
      #
      # @api private
      module_function def matches?(_exists, value, condition)
        unless condition.is_a?(Regexp) || condition.is_a?(BSON::Regexp::Raw)
          # Note that strings must have been converted to a regular expression
          # instance already (with $options taken into account, if provided).
          raise Errors::InvalidQuery, "$regex requires a regular expression argument: #{Errors::InvalidQuery.truncate_expr(condition)}"
        end

        # The condition is compiled by RegexpBudget rather than here, so that
        # the budget's timeout can be baked into the pattern.
        case value
        when Array
          # Object#=~ is gone as of Ruby 3.2, so an element that cannot be
          # matched against has to be rejected rather than passed to =~.
          value.any? do |v|
            v.respond_to?(:=~) && RegexpBudget.match?(v, condition)
          end
        when String
          RegexpBudget.match?(value, condition)
        else
          false
        end
      end

      # Returns whether an scalar or array value matches a Regexp.
      #
      # @param [ true | false ] exists Not used.
      # @param [ String | Array<String> ] value The value to check.
      # @param [ Regexp ] condition The Regexp condition.
      #
      # @return [ true | false ] Whether the value matches.
      #
      # @api private
      module_function def matches_array_or_scalar?(value, condition)
        if value.is_a?(Array)
          value.any? do |v|
            matches?(true, v, condition)
          end
        else
          matches?(true, value, condition)
        end
      end
    end
  end
end
