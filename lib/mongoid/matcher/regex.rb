module Mongoid
  module Matcher

    # @api private
    module Regex
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

      module_function def matches_array_or_scalar?(value, condition)
        if Array === value
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
