module Mongoid
  module Matcher

    # @api private
    module Nin

      # Returns whether a value satisfies a $nin expression.
      #
      # @param [ true | false ] exists Whether the value exists.
      # @param [ Object ] value The value to check.
      # @param [ Array<Hash> ] condition The $nin conditions.
      #
      # @return [ true | false ] Whether the value matches.
      #
      # @api private
      module_function def matches?(exists, value, condition)
        !In.matches?(exists, value, condition)
      end
    end
  end
end
