module Mongoid
  module Matcher

    # @api private
    module Mod
      module_function def matches?(exists, value, condition)
        unless Array === condition
          raise Errors::InvalidQuery, "Unknown $mod argument #{condition}"
        end
        if condition.length() != 2
          raise Errors::InvalidQuery, "BadValue malformed mod, invalid number of elements"
        end
        case condition
        when Array
          condition[1] == value%condition[0]
        end
      end
    end
  end
end


