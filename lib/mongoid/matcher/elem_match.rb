module Mongoid
  module Matcher

    # @api private
    module ElemMatch
      module_function def matches?(exists, value, condition)
        unless Hash === condition
          raise Errors::InvalidQuery, "$elemMatch requires a Hash operand: #{Errors::InvalidQuery.truncate_expr(condition)}"
        end
        if Array === value && !value.empty?
          value.any? do |v|
            ElemMatchExpression.matches?(v, condition)
          end
        else
          # Validate the condition is valid, even though we will never attempt
          # matching it.
          condition.each do |k, v|
            k = k.to_s
            if k.start_with?('$')
              begin
                ExpressionOperator.get(k)
              rescue Mongoid::Errors::InvalidExpressionOperator
                begin
                  FieldOperator.get(k)
                rescue Mongoid::Errors::InvalidFieldOperator => exc
                  raise Mongoid::Errors::InvalidElemMatchOperator.new(exc.operator)
                end
              end
            end
          end
          false
        end
      end
    end
  end
end
