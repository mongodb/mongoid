module Mongoid
  module Matcher

    # @api private
    module Size
      module_function def matches?(exists, value, condition)
        if Array === value
          value.length == condition
        else
          false
        end
      end
    end
  end
end
