# encoding: utf-8
module Mongoid
  module Matchable

    # Performs not in checking.
    class Nin < Default

      # Return true if the attribute is not in the value list.
      #
      # @example Do the values match?
      #   matcher.matches?({ :key => 10 })
      #
      # @param [ Hash ] value The values to check.
      #
      # @return [ true, false ] If a value exists.
      def matches?(value)
        attribute_array = @attribute.nil? ? [nil] : Array.wrap(@attribute)
        attribute_array.none? { |e| value.values.first.include?(e) }
      end
    end
  end
end
