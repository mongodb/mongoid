module Mongoid
  module Matcher

    # @api private
    module BitsAnySet
      module_function def matches?(exists, value, condition)
        case condition
          # TODO
          when Array
          # #  array of bits
          when Binary
          #   value & condition
        when Int
          value & condition
        else
          raise Errors::InvalidQuery, "Unknown $bitsAllClear argument #{condition}"
        end
      end
    end
  end
end
