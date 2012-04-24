# encoding: utf-8
module Mongoid #:nodoc:
  module Matchers #:nodoc:

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
        attribute_array = Array.wrap(@attribute)
        value.values.first.any? do |e|
          if e.is_a?(Regexp)
            attribute_array.any? { |_attribute| _attribute =~ e }
          else
            attribute_array.include?(e)
          end
        end
      end
    end
  end
end
