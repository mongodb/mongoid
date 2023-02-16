module Mongoid
  module Matcher

    # @api private
    module Ne

      # Returns whether a value satisfies an $ne expression.
      #
      # @param exists [ true | false ] exists Whether the value exists.
      # @param value [ Object ] value The value to check.
      # @param condition [ Object ] condition The $ne condition.
      #
      # @return [ true | false ] Whether the value matches.
      #
      # @api private
      module_function def matches?(exists, value, condition)
        case condition
        when ::Regexp, BSON::Regexp::Raw
          raise Errors::InvalidQuery, "'$ne' operator does not allow Regexp arguments: #{Errors::InvalidQuery.truncate_expr(condition)}"
        end

        !EqImpl.matches?(exists, value, condition, '$ne')
      end
    end
  end
end
