# frozen_string_literal: true

module Mongoid
  class Criteria
    module Queryable
      # This module encapsulates methods that expand various high level
      # query forms to the MongoDB hash condition selector syntax.
      #
      # @example Example high level form.
      #   Band.where(:foo.gt => 5)
      #
      # @api private
      module Expandable

        private

        # Expands the specified condition to MongoDB syntax.
        #
        # This method is meant to be called when processing the items of
        # a condition hash and the key and the value of each item are
        # already available separately.
        #
        # The following parameter forms are accepted:
        #
        # - field is a string or symbol; value is the field query expresision
        # - field is a Key instance; value is the field query expression
        # - field is a string corresponding to a MongoDB operator; value is
        #   the operator value expression.
        #
        # This method expands the field-value combination to the MongoDB
        # selector syntax and returns an array of
        # [expanded key, expanded value]. The expanded key is converted to
        # a string if it wasn't already a string.
        #
        # @param [ String | Symbol | Key ] field The field to expand.
        # @param [ Object ] value The field's value.
        #
        # @return [ Array<String, Object> ] The expanded field and value.
        def expand_one_condition(field, value)
          kv = field.__expr_part__(value.__expand_complex__, negating?)
          [kv.keys.first.to_s, kv.values.first]
        end

        # Expand criterion values to arrays, to be used with operators that
        # take an array as argument such as $in.
        #
        # @example Convert all the values to arrays.
        #   selectable.with_array_values({ key: 1...4 })
        #
        # @param [ Hash ] criterion The criterion.
        #
        # @return [ Hash ] The $in friendly criterion with array values.
        #
        # @api private
        def expand_condition_to_array_values(criterion)
          if criterion.nil?
            raise ArgumentError, 'Criterion cannot be nil here'
          end

          Hash[criterion.map do |key, value|
            [key, value.__array__]
          end]
        end

      end
    end
  end
end
