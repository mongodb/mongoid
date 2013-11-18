# encoding: utf-8
module Mongoid
  module Matchable

    # Performs non-equivalency checks.
    class Ne < Default

      # Return true if the attribute and first value are not equal.
      #
      # @example Do the values match?
      #   matcher.matches?({ :key => 10 })
      #
      # @param [ Hash ] value The values to check.
      #
      # @return [ true, false ] If a value exists.
      def matches?(value)
        !super(value.values.first)
      end
    end
  end
end
