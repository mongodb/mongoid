# frozen_string_literal: true

module Mongoid
  module Errors

    # Raised when invalid query is passed to an embedded matcher, or an
    # invalid query fragment is passed to the query builder (Criteria object).
    class InvalidQuery < MongoidError

      # Create the new invalid query error.
      #
      # @api private
      def initialize(msg)
        super
      end

      # Stringifies the argument using #inspect and truncates the result to
      # about 100 characters.
      #
      # @param [ Object ] expr An expression to stringify and truncate.
      #
      # @api private
      def self.truncate_expr(expr)
        unless expr.is_a?(String)
          expr = expr.inspect
        end

        if expr.length > 103
          expr = if expr =~ /\A<#((?:.|\n)*)>\z/
            "<##{expr.slice(0, 97)}...>"
          else
            expr.slice(0, 100) + '...'
          end
        end

        expr
      end
    end
  end
end
