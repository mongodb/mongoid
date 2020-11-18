module Mongoid
  module Matcher

    # @api private
    module Mod
      module_function def matches?(exists, value, condition)
        unless Array === condition
          raise Errors::InvalidQuery, "Unknown $mod argument #{condition}"
        end
        if condition.length != 2
          raise Errors::InvalidQuery, "Malformed $mod argument #{condition}, should have 2 elements"
        end
        condition[1] == value%condition[0]
      end
    end
  end
end
