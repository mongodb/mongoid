# frozen_string_literal: true

module Mongoid
  class Criteria
    module Queryable
      # This module encapsulates methods that write query expressions into
      # the Criteria's selector.
      #
      # The query expressions must have already been expanded as necessary.
      # The methods of this module do not perform processing on expression
      # values.
      #
      # Methods in this module do not handle negation - if negation is needed,
      # it must have already been handled upstream of these methods.
      #
      # @api private
      module Storable

        # Adds a field expression to the query.
        #
        # +field+ must be a field name, and it must be a string. The upstream
        # code must have converted other field/key types to the simple string
        # form by the time this method is invoked.
        #
        # +value+ can be of any type, it is written into the selector unchanged.
        #
        # This method performs no processing on the provided field value.
        #
        # Mutates the receiver.
        #
        # @param [ String ] field The field name.
        # @param [ Object ] value The field value.
        #
        # @return [ Storable ] self.
        def add_field_expression(field, value)
          unless field.is_a?(String)
            raise ArgumentError, "Field must be a string: #{field}"
          end

          if field.start_with?('$')
            raise ArgumentError, "Field cannot be an operator (i.e. begin with $): #{field}"
          end

          if selector[field]
            # We already have a restriction by the field we are trying
            # to restrict, combine the restrictions.
            if value.is_a?(Hash) && selector[field].is_a?(Hash) &&
              value.keys.all? { |key|
                key_s = key.to_s
                key_s.start_with?('$') && !selector[field].key?(key_s)
              }
            then
              # Multiple operators can be combined on the same field by
              # adding them to the existing hash.
              new_value = selector[field].merge(value)
              selector.store(field, new_value)
            elsif selector[field] != value
              add_operator_expression('$and', [{field => value}])
            end
          else
            selector.store(field, value)
          end

          self
        end

        # Adds a logical operator expression to the selector.
        #
        # This method only handles logical operators ($and, $nor and $or).
        # It raises ArgumentError if called with another operator. Note that
        # in MQL, $not is a field-level operator and not a query-level one,
        # and therefore $not is not handled by this method.
        #
        # This method takes the operator and the operator value expression
        # separately for callers' convenience. It can be considered to
        # handle storing the hash +{operator => op_expr}+.
        #
        # If the selector consists of a single condition which is the specified
        # operator (on the top level), the new condition given in op_expr is
        # added to the existing conditions for the specified operator.
        # For example, if the selector is currently:
        #
        #     {'$or' => [{'hello' => 'world'}]}
        #
        # ... and operator is '$or' and op_expr is `[{'test' => 123'}]`,
        # the resulting selector will be:
        #
        #     {'$or' => [{'hello' => 'world'}, {'test' => 123}]}
        #
        # This method always adds the new conditions as additional requirements;
        # in other words, it does not implement the ActiveRecord or/nor behavior
        # where the receiver becomes one of the operands. It is expected that
        # code upstream of this method implements such behavior.
        #
        # This method does not simplify values (i.e. if the selector is
        # currently empty and operator is $and, op_expr is written to the
        # selector with $and even if the $and can in principle be elided).
        # Such simplification is also expected to have already been performed
        # by the upstream code.
        #
        # This method mutates the receiver.
        #
        # @param [ String ] operator The operator to add.
        # @param [ Array<Hash> ] op_expr Operator value to add.
        #
        # @return [ Storable ] self.
        def add_logical_operator_expression(operator, op_expr)
          unless operator.is_a?(String)
            raise ArgumentError, "Operator must be a string: #{operator}"
          end

          unless %w($and $nor $or).include?(operator)
            raise ArgumentError, "This method only handles logical operators ($and, $nor, $or). Operator given: #{operator}"
          end

          unless op_expr.is_a?(Array)
            raise Errors::InvalidQuery, "#{operator} argument must be an array: #{Errors::InvalidQuery.truncate_expr(op_expr)}"
          end

          if selector.length == 1 && selector.keys.first == operator
            new_value = selector.values.first + op_expr
            selector.store(operator, new_value)
          elsif operator == '$and' || selector.empty?
            # $and can always be added to top level and it will be combined
            # with whatever other conditions exist.
            if !Mongoid.broken_and && current_value = selector[operator]
              new_value = current_value + op_expr
              selector.store(operator, new_value)
            else
              selector.store(operator, op_expr)
            end
          else
            # Other operators need to be added separately
            if selector[operator]
              add_logical_operator_expression('$and', [operator => op_expr])
            else
              selector.store(operator, op_expr)
            end
          end

          self
        end

        # Adds an operator expression to the selector.
        #
        # This method takes the operator and the operator value expression
        # separately for callers' convenience. It can be considered to
        # handle storing the hash +{operator => op_expr}+.
        #
        # The operator value can be of any type.
        #
        # If the selector already has the specified operator in it (on the
        # top level), the new condition given in op_expr is added to the
        # existing conditions for the specified operator. This is
        # straightforward for $and; for other logical operators, the behavior
        # of this method is to add the new conditions to the existing operator.
        # For example, if the selector is currently:
        #
        #     {'foo' => 'bar', '$or' => [{'hello' => 'world'}]}
        #
        # ... and operator is '$or' and op_expr is `{'test' => 123'}`,
        # the resulting selector will be:
        #
        #     {'foo' => 'bar', '$or' => [{'hello' => 'world'}, {'test' => 123}]}
        #
        # This does not implement an OR between the existing selector and the
        # new operator expression - handling this is the job of upstream
        # methods. This method simply stores op_expr into the selector on the
        # assumption that the existing selector is the correct left hand side
        # of the operation already.
        #
        # For non-logical query-level operators like $where and $text, if
        # there already is a top-level operator with the same name, the
        # op_expr is added to the selector via a top-level $and operator,
        # thus producing a selector having both operator values.
        #
        # This method does not simplify values (i.e. if the selector is
        # currently empty and operator is $and, op_expr is written to the
        # selector with $and even if the $and can in principle be elided).
        #
        # This method mutates the receiver.
        #
        # @param [ String ] operator The operator to add.
        # @param [ Object ] op_expr Operator value to add.
        #
        # @return [ Storable ] self.
        def add_operator_expression(operator, op_expr)
          unless operator.is_a?(String)
            raise ArgumentError, "Operator must be a string: #{operator}"
          end

          unless operator.start_with?('$')
            raise ArgumentError, "Operator must begin with $: #{operator}"
          end

          if %w($and $nor $or).include?(operator)
            return add_logical_operator_expression(operator, op_expr)
          end

          # For other operators, if the operator already exists in the
          # query, add the new condition with $and, otherwise add the
          # new condition to the top level.
          if selector[operator]
            add_logical_operator_expression('$and', [{operator => op_expr}])
          else
            selector.store(operator, op_expr)
          end

          self
        end

        # Adds an arbitrary expression to the query.
        #
        # Field can either be a field name or an operator.
        #
        # Mutates the receiver.
        #
        # @param [ String ] field Field name or operator name.
        # @param [ Object ] value Field value or operator expression.
        #
        # @return [ Storable ] self.
        def add_one_expression(field, value)
          unless field.is_a?(String)
            raise ArgumentError, "Field must be a string: #{field}"
          end

          if field.start_with?('$')
            add_operator_expression(field, value)
          else
            add_field_expression(field, value)
          end
        end

      end
    end
  end
end
