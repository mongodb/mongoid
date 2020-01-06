# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Matchable

    # Checks that all values match.
    class All < Default

      # Return true if the attribute and first value in the hash are equal.
      #
      # @example Do the values match?
      #   matcher._matches?({ :key => 10 })
      #
      # @param [ Hash ] condition The condition to evaluate. This must be
      #   a one-element hash like {'$gt' => 1}.
      #
      # @return [ true, false ] If the values match.
      def _matches?(condition)
        first = condition_value(condition)
        return false if first.is_a?(Array) && first.empty?

        attribute_array = Array.wrap(@attribute)
        first.all? do |e|
          attribute_array.any? { |_attribute| e === _attribute }
        end
      end
    end
  end
end
