# encoding: utf-8
module Mongoid
  module Matchable

    # Performs matching for any value in an array.
    class In < Default

      # Return true if the attribute is in the values.
      #
      # @example Do the values match?
      #   matcher.matches?({ :key => 10 })
      #
      # @param [ Hash ] value The values to check.
      #
      # @return [ true, false ] If a value exists.
      def matches?(value)
        attribute_array = @attribute.nil? ? [nil] : Array.wrap(@attribute)
        value.values.first.any? do |e|
          attribute_array.any? { |_attribute| e === _attribute }
        end
      end
    end
  end
end
