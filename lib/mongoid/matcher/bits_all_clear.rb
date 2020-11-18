module Mongoid
  module Matcher

    # @api private
    module BitsAllClear
      module_function def matches?(exists, value, condition)
        case value
        when BSON::Binary
          value = value.data.split('').map { |n| '%02x' % n.ord }.join.to_i(16)
        end
        case condition
        when Array
          condition.all? do |c|
            value & (1<<c) == 0
          end
        when BSON::Binary
          #condition is a binary string
          # TODO: test logic to convert to integer
          int_cond = condition.data.split('').map { |n| '%02x' % n.ord }.join.to_i(16)
          value & int_cond == 0
        when Integer
          value & condition == 0
        else
          raise Errors::InvalidQuery, "Unknown $bitsAllClear argument #{condition}"
        end
      end
    end
  end
end
