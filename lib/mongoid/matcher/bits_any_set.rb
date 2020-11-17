module Mongoid
  module Matcher

    # @api private
    module BitsAnySet
      module_function def matches?(exists, value, condition)
        case condition
        when Array
          #  array of bits
          condition.any? do |c|
            value & (1<<c) > 0
          end
        when BSON::Binary
          #   value & condition
        when Integer
          value & condition > 0
        else
          raise Errors::InvalidQuery, "Unknown $bitsAllClear argument #{condition}"
        end
      end
    end
  end
end
