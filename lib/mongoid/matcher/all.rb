module Mongoid
  module Matcher

    # @api private
    module All
      module_function def matches?(exists, value, condition)
        unless Array === condition
          raise Errors::InvalidQuery, "$all argument must be an array: #{Errors::InvalidQuery.truncate_expr(condition)}"
        end

        !condition.empty? && condition.all? do |c|
          case c
          when ::Regexp, BSON::Regexp::Raw
            Regex.matches_array_or_scalar?(value, c)
          else
            EqImpl.matches?(true, value, c, '$all')
          end
        end
      end
    end
  end
end
