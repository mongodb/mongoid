module Mongoid
  module Matcher

    # @api private
    module FieldExpression
      module_function def matches?(exists, value, condition)
        if condition.is_a?(Hash)
          condition.all? do |k, cond_v|
            k = k.to_s
            if k.start_with?('$')
              if %w($regex $options).include?(k)
                unless condition.key?('$regex')
                  raise Errors::InvalidQuery, "$regex is required if $options is given: #{Errors::InvalidQuery.truncate_expr(condition)}"
                end

                if k == '$regex'
                  if options = condition['$options']
                    cond_v = case cond_v
                    when Regexp
                      BSON::Regexp::Raw.new(cond_v.source, options)
                    when BSON::Regexp::Raw
                      BSON::Regexp::Raw.new(cond_v.pattern, options)
                    else
                      BSON::Regexp::Raw.new(cond_v, options)
                    end
                  elsif String === cond_v
                    cond_v = BSON::Regexp::Raw.new(cond_v)
                  end

                  FieldOperator.get(k).matches?(exists, value, cond_v)
                else
                  # $options are matched as part of $regex
                  true
                end
              else
                FieldOperator.get(k).matches?(exists, value, cond_v)
              end
            elsif Hash === value
              sub_values = Matcher.extract_attribute(value, k)
              if sub_values.length > 0
                sub_values.any? do |sub_v|
                  Eq.matches?(true, sub_v, cond_v)
                end
              else
                Eq.matches?(false, nil, cond_v)
              end
            else
              false
            end
          end
        else
          case condition
          when ::Regexp, BSON::Regexp::Raw
            Regex.matches_array_or_scalar?(value, condition)
          else
            Eq.matches?(exists, value, condition)
          end
        end
      end
    end
  end
end
