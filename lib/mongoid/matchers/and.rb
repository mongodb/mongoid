# encoding: utf-8
module Mongoid
  module Matchers

    # Defines behavior for handling $or expressions in embedded documents.
    class And < Default

      # Does the supplied query match the attribute?
      #
      # @example Does this match?
      #   matcher.matches?([ { field => value } ])
      #
      # @param [ Array ] conditions The or expression.
      #
      # @return [ true, false ] True if matches, false if not.
      #
      # @since 2.3.0
      def matches?(conditions)
        conditions.each do |condition|
          condition.keys.each do |k|
            key = k
            value = condition[k]
            return false unless Strategies.matcher(document, key, value).matches?(value)
          end
        end
        true
      end
    end
  end
end
