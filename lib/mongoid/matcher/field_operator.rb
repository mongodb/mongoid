# rubocop:todo all
module Mongoid
  module Matcher

    # Singleton module provides lookup of query operator matchers
    # related to field values.
    #
    # @api private
    module FieldOperator
      MAP = {
        '$all' => All,
        '$bitsAllClear' => BitsAllClear,
        '$bitsAllSet' => BitsAllSet,
        '$bitsAnyClear' => BitsAnyClear,
        '$bitsAnySet' => BitsAnySet,
        '$elemMatch' => ElemMatch,
        '$eq' => Eq,
        '$exists' => Exists,
        '$gt' => Gt,
        '$gte' => Gte,
        '$in' => In,
        '$lt' => Lt,
        '$lte' => Lte,
        '$mod' => Mod,
        '$nin' => Nin,
        '$ne' => Ne,
        '$not' => Not,
        '$regex' => Regex,
        '$size' => Size,
        '$type' => Type,
      }.freeze

      # Returns the matcher module for a given operator.
      #
      # @param [ String ] op The operator name.
      #
      # @return [ Module ] The matcher module.
      #
      # @raises [ Mongoid::Errors::InvalidFieldOperator ]
      #   Raised if the given operator is unknown.
      #
      # @api private
      module_function def get(op)
        MAP.fetch(op)
      rescue KeyError
        raise Errors::InvalidFieldOperator.new(op)
      end

      # Used for evaluating $lt, $lte, $gt, $gte comparison operators.
      #
      # @todo Refactor this as it is only relevant to $lt, $lte, $gt, $gte.
      #
      # @api private
      module_function def apply_array_field_operator(exists, value, condition)
        if Array === value
          value.any? { |v| yield v }
        else
          yield value
        end
      end

      # Used for evaluating $lt, $lte, $gt, $gte comparison operators.
      #
      # @todo Refactor this as it is only relevant to $lt, $lte, $gt, $gte.
      #
      # @api private
      module_function def apply_comparison_operator(operator, left, right)
        left.send(operator, right)
      rescue ArgumentError, NoMethodError, TypeError
        # We silence bogus comparison attempts, e.g. number to string
        # comparisons.
        # Several different exceptions may be produced depending on the types
        # involved.
        false
      end
    end
  end
end
