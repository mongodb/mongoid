module Mongoid
  module Matcher

    # @api private
    module FieldExpression
      module_function def matches?(exists, value, condition)
        if condition.is_a?(Hash)
          condition.all? do |k, cond_v|
            k = k.to_s
            if k.start_with?('$')
              FieldOperator.get(k).matches?(exists, value, cond_v)
            elsif Hash === value
              sub_value, expanded = Matcher.extract_attribute(value, k)
              if expanded
                sub_value.any? do |sub_v|
                  Eq.matches?(true, sub_v, cond_v)
                end
              else
                Eq.matches?(!sub_value.nil?, sub_value, cond_v)
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
