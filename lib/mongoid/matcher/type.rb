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
                       [ condition ]
                     else
                       raise Errors::InvalidQuery, "Unknown $type argument: #{condition}"
                     end
        conditions.each do |condition|
          return true if one_matches?(exists, value, condition)
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
          value.is_a?(Float)
        when 2
          # String
          value.is_a?(String)
        when 3
          # Object
          value.is_a?(Hash)
        when 4
          # Array
          value.is_a?(Array)
        when 5
          # Binary data
          value.is_a?(BSON::Binary)
        when 6
          # Undefined
          value.is_a?(BSON::Undefined)
        when 7
          # ObjectId
          value.is_a?(BSON::ObjectId)
        when 8
          # Boolean
          value.is_a?(TrueClass) || value.is_a?(FalseClass)
        when 9
          # Date
          value.is_a?(Date) || value.is_a?(Time) || value.is_a?(DateTime)
        when 10
          # Null
          exists && value.is_a?(NilClass)
        when 11
          # Regex
          value.is_a?(Regexp::Raw) || value.is_a?(::Regexp)
        when 12
          # DBPointer deprecated
          value.is_a?(BSON::DbPointer)
        when 13
          # JavaScript
          value.is_a?(BSON::Code)
        when 14
          # Symbol deprecated
          value.is_a?(Symbol) || value.is_a?(BSON::Symbol::Raw)
        when 15
          # Javascript with code deprecated
          value.is_a?(BSON::CodeWithScope)
        when 16
          # 32-bit int
          value.is_a?(BSON::Int32) || (value.is_a?(Integer) && (-2**32..(2**32) - 1).include?(value))
        when 17
          # Timestamp
          value.is_a?(BSON::Timestamp)
        when 18
          # Long
          value.is_a?(BSON::Int64) ||
            (value.is_a?(Integer) &&
              (-2**64..(2**64) - 1).include?(value) &&
              !(-2**32..(2**32) - 1).include?(value))
        when 19
          # Decimal
          value.is_a?(BSON::Decimal128)
        when -1
          # minKey
          value.is_a?(BSON::MinKey)
        when 127
          # maxKey
          value.is_a?(BSON::MaxKey)
        else
          raise Errors::InvalidQuery, "Unknown $type argument: #{condition}"
        end
      end
    end
  end
end
