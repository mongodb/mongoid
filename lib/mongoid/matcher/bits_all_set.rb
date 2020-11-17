module Mongoid
  module Matcher

    # @api private
    module BitsAllSet
      module_function def matches?(exists, value, condition)
        case condition
        # TODO
        when Array
          condition.all? do |c|
            value & (1<<c) > 0
          end
        when BSON::Binary
        when Integer
          value & condition == condition
        else
          raise Errors::InvalidQuery, "Unknown $bitsAllClear argument #{condition}"
        end
      end
    end
  end
end
