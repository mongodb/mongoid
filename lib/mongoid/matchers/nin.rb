# encoding: utf-8
module Mongoid #:nodoc:
  module Matchers #:nodoc:

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
        Array.wrap(@attribute).none? { |e| value.values.first.include?(e) }
      end
    end
  end
end
