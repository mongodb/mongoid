module Mongoid
  module Matcher

    # @api private
    module BitsAnyClear
      module_function def matches?(exists, value, condition)
        case condition
          # TODO
          when Array
          # #  array of bits
            condition.any? do |c|
              value & (1<<c) == 0
            end
          # https://www.geeksforgeeks.org/check-whether-bit-given-position-set-unset/
        when BSON::Binary
        when Integer
          # byebug
          # todo: simplify
          (value & condition == 0) || (!(value & condition == condition) && (value & condition > 0))
        else
          raise Errors::InvalidQuery, "Unknown $bitsAllClear argument #{condition}"
        end
      end
    end
  end
end
