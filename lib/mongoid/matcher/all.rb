# rubocop:todo all
module Mongoid
  module Matcher

    # In-memory matcher for $all expression.
    #
    # @see https://www.mongodb.com/docs/manual/reference/operator/query/all/
    #
    # @api private
    module All

      # Returns whether a value satisfies an $all expression.
      #
      # @param [ true | false ] exists Not used.
      # @param [ Object ] value The value to check.
      # @param [ Array<Object> ] condition The $all condition predicate.
      #
      # @return [ true | false ] Whether the value matches.
      #
      # @api private
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
