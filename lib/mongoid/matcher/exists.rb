module Mongoid
  module Matcher

    # @api private
    module Exists
      module_function def matches?(exists, value, condition)
        exists == (condition || false)
      end
    end
  end
end
