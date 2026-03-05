# rubocop:todo all
module Mongoid
  module Matcher

    # In-memory matcher for $not expression.
    #
    # @see https://www.mongodb.com/docs/manual/reference/operator/query/not/
    #
    # @api private
    module Not

      # Returns whether a value satisfies an $not expression.
      #
      # @param [ true | false ] exists Whether the value exists.
      # @param [ Object ] value The value to check.
      # @param [ Hash | Regexp | BSON::Regexp::Raw ] condition
      #   The $not condition predicate.
      #
      # @return [ true | false ] Whether the value matches.
      #
      # @api private
      module_function def matches?(exists, value, condition)
        case condition
        when ::Regexp, BSON::Regexp::Raw
          !Regex.matches?(exists, value, condition)
        when Hash
          if condition.empty?
            raise Errors::InvalidQuery, "$not argument cannot be an empty hash: #{Errors::InvalidQuery.truncate_expr(condition)}"
          end

          condition.all? do |(k, cond_v)|
            k = k.to_s
            unless k.start_with?('$')
              raise Errors::InvalidQuery, "$not arguments must be operators: #{Errors::InvalidQuery.truncate_expr(k)}"
            end

            !FieldOperator.get(k).matches?(exists, value, cond_v)
          end
        else
          raise Errors::InvalidQuery, "$not argument must be a Hash or a regular expression: #{Errors::InvalidQuery.truncate_expr(condition)}"
        end
      end
    end
  end
end
