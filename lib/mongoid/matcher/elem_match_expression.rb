# rubocop:todo all
module Mongoid
  module Matcher

    # In-memory matcher used to evaluate whether an $elemMatch predicate
    # matches and individual document. The $elemMatch predicate can be a
    # logical expressions including $and, $or, $nor, and $not. $not can
    # also have a regular expression predicate.
    #
    # @api private
    module ElemMatchExpression

      # Returns whether a document satisfies an $elemMatch expression.
      #
      # @param [ Mongoid::Document ] document The document.
      # @param [ Hash ] expr The $elemMatch condition predicate.
      #
      # @return [ true | false ] Whether the document matches.
      #
      # @api private
      module_function def matches?(document, expr)
        Expression.matches?(document, expr)
      rescue Mongoid::Errors::InvalidExpressionOperator
        begin
          FieldExpression.matches?(true, document, expr)
        rescue Mongoid::Errors::InvalidFieldOperator => exc
          raise Mongoid::Errors::InvalidElemMatchOperator.new(exc.operator)
        end
      end
    end
  end
end
