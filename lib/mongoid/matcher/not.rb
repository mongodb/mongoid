module Mongoid
  module Matcher

    # @api private
    module Not
      module_function def matches?(exists, value, condition)
        case condition
        when ::Regexp, BSON::Regexp::Raw
          !Regex.matches?(exists, value, condition)
        else
          condition.all? do |(k, cond_v)|
            k = k.to_s
            unless k.start_with?('$')
              raise Errors::InvalidQuery, "'$not' operator arguments must be operators: #{Errors::InvalidQuery.truncate_expr(k)}"
            end

            !FieldOperator.get(k).matches?(exists, value, cond_v)
          end
        end
      end
    end
  end
end
