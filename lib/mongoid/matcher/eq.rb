module Mongoid
  module Matcher

    # @api private
    module Eq
      module_function def matches?(exists, value, condition)
        EqImpl.matches?(exists, value, condition, '$eq')
      end
    end
  end
end
