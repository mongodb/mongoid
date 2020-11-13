module Mongoid
  module Matcher

    # @api private
    module BitsAllClear
      module_function def matches?(exists, value, condition)
        # byebug
        # p condition
        case condition
        when Array
        #  array of bits
        # TODO
        when BSON::Binary
          #condition is a binary string
          # TODO: add logic to convert to integer
        when Integer
          value & condition
        else
          raise Errors::InvalidQuery, "Unknown $bitsAllClear argument #{condition}"
        end
      end
    end
  end
end
