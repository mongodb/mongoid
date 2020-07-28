module Mongoid
  module Matcher

    # @api private
    module Gte
      module_function def matches?(exists, value, condition)
        case condition
        when Range
          raise Errors::InvalidQuery, "$gte argument cannot be a Range: #{Errors::InvalidQuery.truncate_expr(condition)}"
        end
        FieldOperator.apply_array_field_operator(exists, value, condition) do |v|
          FieldOperator.apply_comparison_operator(:>=, v, condition)
        end
      end
    end
  end
end
