module Mongoid
  module Matcher

    # @api private
    module Nin
      module_function def matches?(exists, value, condition)
        !In.matches?(exists, value, condition)
      end
    end
  end
end
