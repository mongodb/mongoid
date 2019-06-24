# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Matchable

    # Defines behavior for handling $and expressions in embedded documents.
    class And < Default

      # Does the supplied query match the attribute?
      #
      # @example Does this match?
      #   matcher._matches?([ { field => value } ])
      #
      # @param [ Array ] conditions The or expression.
      #
      # @return [ true, false ] True if matches, false if not.
      #
      # @since 2.3.0
      def _matches?(conditions)
        conditions.each do |condition|
          condition.keys.each do |k|
            key = k
            value = condition[k]
            return false unless document._matches?(key => value)
          end
        end
        true
      end
    end
  end
end
