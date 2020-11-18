module Mongoid
  module Matcher

    # @see https://docs.mongodb.com/manual/reference/operator/query/type/
    #
    # @api private
    module Type
      module_function def matches?(exists, value, condition)
        case condition
        when Array
          condition.any? do |v|
            condition = v
          end
        when 1
          #TODO: MATCH BSON TYPES

          # Double
          Float === value || BSON::Float === value
        when 2
          # String
          String === value || BSON::String === value
        when 3
          # Object
          Object === value || BSON::Object === value
        when 4
          # Array
          Array === value || BSON::Array === value
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
          TrueClass === value || FalseClass === value || BSON::Boolean === value
        when 9
          # Date
          BSON::Date === value
        when 10
          # Null
          BSON::NilClass === value
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
          BSON::Int32 === value
        when 17
          # Timestamp
          BSON::Timestamp === value
        when 18
          # Long
          BSON::Int64 === value
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
          raise Errors::InvalidQuery, "Unknown $type argument #{condition}"
        end
      end
    end
  end
end

