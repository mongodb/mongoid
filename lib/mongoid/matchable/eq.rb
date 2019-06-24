# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Matchable

    # Performs equivalency checks.
    class Eq < Default

      # Return true if the attribute and first value are equal.
      #
      # @example Do the values match?
      #   matcher._matches?({ :key => 10 })
      #
      # @param [ Hash ] value The values to check.
      #
      # @return [ true, false ] True if matches, false if not.
      def _matches?(value)
        super(value.values.first)
      end
    end
  end
end
