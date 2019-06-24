# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Matchable

    # Defines behavior for handling $nor expressions in embedded documents.
    class Nor < Default

      # Does the supplied query match the attribute?
      #
      # Note: an empty array as an argument to $nor is prohibited by
      # MongoDB server. Mongoid does allow this and returns false in this case.
      #
      # @example Does this match?
      #   matcher._matches?("$nor" => [ { field => value } ])
      #
      # @param [ Array ] conditions The or expression.
      #
      # @return [ true, false ] True if matches, false if not.
      #
      # @since 7.1.0
      def _matches?(conditions)
        if conditions.length == 0
          # MongoDB does not allow $nor array to be empty, but
          # Mongoid accepts an empty array for $or which MongoDB also
          # prohibits
          return false
        end
        conditions.none? do |condition|
          condition.all? do |key, value|
            document._matches?(key => value)
          end
        end
      end
    end
  end
end
