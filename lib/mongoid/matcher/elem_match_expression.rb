module Mongoid
  module Matcher

    # $elemMatch argument can be a top-level expression and some specific
    # operator combinations like $not with a regular expression.
    #
    # @api private
    module ElemMatchExpression

      # Returns whether a document satisfies an $elemMatch expression.
      #
      # @param document [ Mongoid::Document ] document The document.
      # @param expr [ Hash ] expr The $elemMatch condition.
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
