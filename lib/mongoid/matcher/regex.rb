module Mongoid
  module Matcher

    # @api private
    module Regex
      module_function def matches?(exists, value, condition)
        if condition.respond_to?(:compile)
          # BSON::Regexp::Raw
          condition = condition.compile
        end
        case condition
        when Regexp
          value =~ condition
        when String
          value =~ Regexp.new(condition)
        else
          raise Errors::InvalidQuery, "$regex requires a regular expression or a string argument: #{Errors::InvalidQuery.truncate_expr(condition)}"
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
