# encoding: utf-8
module Mongoid
  module Matchable

    # Defines behavior for handling $nor expressions in embedded documents.
    class Nor < Default

      # Does the supplied query match the attribute?
      #
      # @example Does this match?
      #   matcher._matches?("$nor" => [ { field => value } ])
      #
      # @param [ Array ] conditions The or expression.
      #
      # @return [ true, false ] True if matches, false if not.
      #
      # @since 2.0.0.rc.7
      def _matches?(conditions)
        conditions.each do |condition|
          condition.keys.each do |k|
            key = k
            value = condition[k]
            # $nor returns true if all conditions in the array fail, so if one matches, then we failed
            if document._matches?(key => value)
              return false
            end
          end
        end
        return true
      end
    end
  end
end
