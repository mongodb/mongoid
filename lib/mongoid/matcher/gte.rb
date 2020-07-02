module Mongoid
  module Matcher

    # @api private
    module Gte
      module_function def matches?(exists, value, condition)
        FieldOperator.apply_array_field_operator(exists, value, condition) do |v|
          FieldOperator.soft_apply_operator(:>=, v, condition)
        end
      end
    end
  end
end
