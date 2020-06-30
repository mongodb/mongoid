module Mongoid
  module Matcher

    # @api private
    module ElemMatch
      module_function def matches?(exists, value, condition)
        unless Hash === condition
          raise Errors::InvalidQuery, "$elemMatch requires a Hash operand: #{Errors::InvalidQuery.truncate_expr(condition)}"
        end
        if Array === value
          value.any? do |v|
            # TODO restrict allowed expressions
            ElemMatchExpression.matches?(v, condition)
          end
        else
          false
        end
      end
    end
  end
end
