module Mongoid
  module Matcher

    # @api private
    module Nor
      module_function def matches?(document, expr)
        unless expr.is_a?(Array)
          raise Errors::InvalidQuery, "$nor argument must be an array: #{Errors::InvalidQuery.truncate_expr(expr)}"
        end

        if expr.empty?
          raise Errors::InvalidQuery, "$nor argument must be a non-empty array: #{Errors::InvalidQuery.truncate_expr(expr)}"
        end

        expr.each do |sub_expr|
          if Expression.matches?(document, sub_expr)
            return false
          end
        end

        expr.any?
      end
    end
  end
end
