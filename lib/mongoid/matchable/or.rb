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
        conditions.each do |condition|
          res = true
          condition.keys.each do |k|
            key = k
            value = condition[k]
            res &&= document._matches?(key => value)
            break unless res
          end
          return res if res
        end
        return false
      end
    end
  end
end
