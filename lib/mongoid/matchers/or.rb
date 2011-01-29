# encoding: utf-8
module Mongoid #:nodoc:
  module Matchers #:nodoc:

    # Defines behavior for handling $or expressions in embedded documents.
    class Or < Default

      # Does the supplied query match the attribute?
      #
      # @example Does this match?
      #   matcher.matches?("$or" => [ { field => value } ])
      #
      # @param [ Array ] conditions The or expression.
      #
      # @return [ true, false ] True if matches, false if not.
      #
      # @since 2.0.0.rc.7
      def matches?(conditions)
        conditions.each do |condition|
          key = condition.keys.first
          value = condition.values.first
          if Strategies.matcher(document, key, value).matches?(value)
            return true
          end
        end
        return false
      end
    end
  end
end
