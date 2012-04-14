# encoding: utf-8
module Mongoid
  module Matchers

    # Checks that all values match.
    class All < Default

      # Return true if the attribute and first value in the hash are equal.
      #
      # @example Do the values match?
      #   matcher.matches?({ :key => 10 })
      #
      # @param [ Hash ] value The values to check.
      #
      # @return [ true, false ] If the values match.
      def matches?(value)
        attribute_array = Array.wrap(@attribute)
        first(value).all? do |e|
          attribute_array.any? { |_attribute| e === _attribute }
        end
      end
    end
  end
end
