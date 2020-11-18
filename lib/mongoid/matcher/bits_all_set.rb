module Mongoid
  module Matcher

    # @api private
    module BitsAllSet
      module_function def matches?(exists, value, condition)
        case value
        when BSON::Binary
          value = value.data.split('').map { |n| '%02x' % n.ord }.join.to_i(16)
        end
        case condition
        when Array
          condition.all? do |c|
            value & (1<<c) > 0
          end
        when BSON::Binary
          int_cond = condition.data.split('').map { |n| '%02x' % n.ord }.join.to_i(16)
          value & int_cond == int_cond
        when Integer
          value & condition == condition
        else
          raise Errors::InvalidQuery, "Unknown $bitsAllClear argument #{condition}"
        end
      end
    end
  end
end
