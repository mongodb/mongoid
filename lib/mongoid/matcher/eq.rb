module Mongoid
  module Matcher

    # @api private
    module Eq

      # Returns whether a value satisfies an $eq expression.
      #
      # @param exists [ true | false ] exists Whether the value exists.
      # @param value [ Array | Object ] value The value to check.
      # @param condition [ Hash ] expr The condition.
      #
      # @return [ true | false ] Whether the value matches.
      #
      # @api private
      module_function def matches?(exists, value, condition)
        EqImpl.matches?(exists, value, condition, '$eq')
      end
    end
  end
end
