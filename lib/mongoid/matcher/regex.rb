module Mongoid
  module Matcher

    # @api private
    module Regex
      module_function def matches?(exists, value, condition)
        condition = case condition
        when Regexp
          condition
        when BSON::Regexp::Raw
          condition.compile
        else
          # Note that strings must have been converted to a regular expression
          # instance already (with $options taken into account, if provided).
          raise Errors::InvalidQuery, "$regex requires a regular expression argument: #{Errors::InvalidQuery.truncate_expr(condition)}"
        end

        case value
        when Array
          value.any? do |v|
            v =~ condition
          end
        when String
          value =~ condition
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
