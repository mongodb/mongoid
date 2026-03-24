module Mongoid
  module Matcher
    # In-memory matcher for $elemMatch expression.
    #
    # @see https://www.mongodb.com/docs/manual/reference/operator/query/elemMatch/
    #
    # @api private
    module ElemMatch
      # Returns whether a value satisfies an $elemMatch expression.
      #
      # @param [ true | false ] exists Not used.
      # @param [ Object | Array<Object> ] value The value to check.
      # @param [ Hash ] expr The $elemMatch condition predicate.
      #
      # @return [ true | false ] Whether the value matches.
      #
      # @api private
      module_function def matches?(_exists, value, condition)
        unless condition.is_a?(Hash)
          raise Errors::InvalidQuery, "$elemMatch requires a Hash operand: #{Errors::InvalidQuery.truncate_expr(condition)}"
        end

        if value.is_a?(Array) && !value.empty?
          value.any? do |v|
            ElemMatchExpression.matches?(v, condition)
          end
        else
          # Validate the condition is valid, even though we will never attempt
          # matching it.
          condition.each do |k, _v|
            k = k.to_s
            next unless k.start_with?('$')

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
          false
        end
      end
    end
  end
end
