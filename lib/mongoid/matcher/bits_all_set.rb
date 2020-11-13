module Mongoid
  module Matcher

    # @api private
    module BitsAllSet
      module_function def matches?(exists, value, condition)
        case condition
        # TODO
        when Array
        when Binary
        when Int
        else
          raise Errors::InvalidQuery, "Unknown $bitsAllClear argument #{condition}"
        end
      end
    end
  end
end
