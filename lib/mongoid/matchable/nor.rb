# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Matchable

    # Defines behavior for handling $nor expressions in embedded documents.
    class Nor < Logical

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
        # MongoDB prohibits $or with empty condition list.
        # Mongoid currently accepts such a construct, and returns false.
        conditions.each do |condition|
          if document._matches?(condition)
            return false
          end
        end
        !conditions.empty?
      end
    end
  end
end
