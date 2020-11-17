module Mongoid
  module Matcher

    # @see https://docs.mongodb.com/manual/reference/operator/query/type/
    #
    # @api private
    module Type
      module_function def matches?(exists, value, condition)
        p value
        case condition
        when Array
          condition.any? do |v|
            condition = v
          end
        when 1
          # Double
          Float === value
        when 2
          # String
          String === value
        when 3
          # Object
          Object === value
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
          Date === value
        when 10
          # Null
          NilClass === value
        when 11
          # Regex
          Regexp::Raw === value || ::Regexp === value
        when 12
          # DBPointer deprecated
          DBPointer === value
        when 13
          # JavaScript
          Code === value
        when 14
          # Symbol deprecated
          Symbol === value || BSON::Symbol::Raw === value
        when 15
          # Javascript with code deprecated
          CodeWithScope === value
        when 16
          # 32-bit int
          Integer === value
        when 17
          # Timestamp
          Time === value
        when 18
          # Long
          Bignum === value
        when 19
          # Decimal
          BigDecimal === value
        when -1
        #  TODO: need to check it's actually the minimum value
        # minKey
          true
        when 127
          # TODO: need to check it's actually the maximum value
          # maxKey
          true
        else
          raise Errors::InvalidQuery, "Unknown $type argument #{condition}"
        end
      end
    end
  end
end