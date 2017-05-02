# encoding: utf-8
module Mongoid
  module Matchable

    # Checks for existence.
    class Exists < Default

      # Return true if the attribute exists and checking for existence or
      # return true if the attribute does not exist and checking for
      # non-existence.
      #
      # @example Does anything exist?
      #   matcher._matches?({ :key => 10 })
      #
      # @param [ Hash ] value The values to check.
      #
      # @return [ true, false ] If a value exists.
      def _matches?(value)
        @attribute.nil? != value.values.first
      end
    end
  end
end
