# encoding: utf-8
module Mongoid
  module Matchable

    # Performs less than or equal to matching.
    class Lte < Default

      # Return true if the attribute is less than or equal to the value.
      #
      # @example Do the values match?
      #   matcher._matches?({ :key => 10 })
      #
      # @param [ Hash ] value The values to check.
      #
      # @return [ true, false ] If a value exists.
      def _matches?(value)
        determine(value, :<=)
      rescue ArgumentError
        false
      end
    end
  end
end
