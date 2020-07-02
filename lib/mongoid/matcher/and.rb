module Mongoid
  module Matcher

    # @api private
    module And
      module_function def matches?(document, expr)
        unless expr.is_a?(Array)
          raise Errors::InvalidQuery, "$and argument must be an array: #{Errors::InvalidQuery.truncate_expr(expr)}"
        end

        if expr.empty?
          raise Errors::InvalidQuery, "$and argument must be a non-empty array: #{Errors::InvalidQuery.truncate_expr(expr)}"
        end

        expr.all? do |sub_expr|
          Expression.matches?(document, sub_expr)
        end
      end
    end
  end
end
