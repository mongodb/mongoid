module Mongoid
  module Matcher

    # @api private
    module Not
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
