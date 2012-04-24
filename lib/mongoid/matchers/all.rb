# encoding: utf-8
module Mongoid #:nodoc:
  module Matchers #:nodoc:

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
        value.values.first.all? do |e|
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
