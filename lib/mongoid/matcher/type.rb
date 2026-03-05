# rubocop:todo all
module Mongoid
  module Matcher

    # In-memory matcher for $type expression.
    #
    # @see https://www.mongodb.com/docs/manual/reference/operator/query/type/
    #
    # @api private
    module Type

      # Returns whether a value satisfies a $type expression.
      #
      # @param [ true | false ] exists Whether the value exists.
      # @param [ Object ] value The value to check.
      # @param [ Integer | Array<Integer> ] condition The $type condition
      #   predicate which corresponds to the BSON type enumeration.
      #
      # @return [ true | false ] Whether the value matches.
      #
      # @api private
      module_function def matches?(exists, value, condition)
        conditions = case condition
        when Array
          condition
        when Integer
          [condition]
        else
          raise Errors::InvalidQuery, "Unknown $type argument: #{condition}"
        end
        conditions.each do |condition|
          if one_matches?(exists, value, condition)
            return true
          end
        end
        false
      end

      # Returns whether a value satisfies a single $type expression
      # value.
      #
      # @param [ true | false ] exists Whether the value exists.
      # @param [ Object ] value The value to check.
      # @param [ Integer ] condition The $type condition predicate
      #   which corresponds to the BSON type enumeration.
      #
      # @return [ true | false ] Whether the value matches.
      #
      # @api private
      module_function def one_matches?(exists, value, condition)
        case condition
        when 1
          # Double
          Float === value
        when 2
          # String
          String === value
        when 3
          # Object
          Hash === value
        when 4
          # Array
          Array === value
        when 5
          # Binary data
          BSON::Binary === value
        when 6
          # Undefined
          BSON::Undefined === value
        when 7
          # ObjectId
          BSON::ObjectId === value
        when 8
          # Boolean
          TrueClass === value || FalseClass === value
        when 9
          # Date
          Date === value || Time === value || DateTime === value
        when 10
          # Null
          exists && NilClass === value
        when 11
          # Regex
          Regexp::Raw === value || ::Regexp === value
        when 12
          # DBPointer deprecated
          BSON::DbPointer === value
        when 13
          # JavaScript
          BSON::Code === value
        when 14
          # Symbol deprecated
          Symbol === value || BSON::Symbol::Raw === value
        when 15
          # Javascript with code deprecated
          BSON::CodeWithScope === value
        when 16
          # 32-bit int
          BSON::Int32 === value || Integer === value && (-2**32..2**32-1).include?(value)
        when 17
          # Timestamp
          BSON::Timestamp === value
        when 18
          # Long
          BSON::Int64 === value ||
            Integer === value &&
              (-2**64..2**64-1).include?(value) &&
              !(-2**32..2**32-1).include?(value)
        when 19
          # Decimal
          BSON::Decimal128 === value
        when -1
          # minKey
          BSON::MinKey === value
        when 127
          # maxKey
          BSON::MaxKey === value
        else
          raise Errors::InvalidQuery, "Unknown $type argument: #{condition}"
        end
      end
    end
  end
end
