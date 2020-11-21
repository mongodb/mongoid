module Mongoid
  module Matcher

    # @api private
    module FieldOperator
      MAP = {
        '$all' => All,
        '$elemMatch' => ElemMatch,
        '$eq' => Eq,
        '$exists' => Exists,
        '$gt' => Gt,
        '$gte' => Gte,
        '$in' => In,
        '$lt' => Lt,
        '$lte' => Lte,
        '$nin' => Nin,
        '$ne' => Ne,
        '$not' => Not,
        '$regex' => Regex,
        '$size' => Size,
        '$type' => Type,
      }.freeze

      module_function def get(op)
        MAP.fetch(op)
      rescue KeyError
        raise Errors::InvalidFieldOperator.new(op)
      end

      module_function def apply_array_field_operator(exists, value, condition)
        if Array === value
          value.any? { |v| yield v }
        else
          yield value
        end
      end

      module_function def apply_comparison_operator(operator, left, right)
        case left
        when Numeric
          case right
          when Numeric
            left.send(operator, right)
          else
            false
          end
        else
          false
        end
      end
    end
  end
end
