# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Matchable

    # Defines behavior for handling $or expressions in embedded documents.
    class Or < Default

      # Does the supplied query match the attribute?
      #
      # @example Does this match?
      #   matcher._matches?("$or" => [ { field => value } ])
      #
      # @param [ Array ] conditions The or expression.
      #
      # @return [ true, false ] True if matches, false if not.
      #
      # @since 2.0.0.rc.7
      def _matches?(conditions)
        # MongoDB prohibits $or with empty condition list.
        # Mongoid currently accepts such a construct, and returns false.
        conditions.each do |condition|
          if document._matches?(condition)
            return true
          end
        end
        false
      end
    end
  end
end
