# encoding: utf-8
module Mongoid
  module Matchable

    class ElemMatch < Default

      # Return true if a given predicate matches a sub document entirely
      #
      # @example Do the values match?
      #   matcher._matches?({"$elemMatch" => {"a" => 1, "b" => 2}})
      #
      # @param [ Hash ] value The values to check.
      #
      # @return [ true, false ] If the values match.
      def _matches?(value)
        if !@attribute.is_a?(Array) || !value.kind_of?(Hash) || !value["$elemMatch"].kind_of?(Hash)
          return false
        end

        return @attribute.any? do |sub_document|
          value["$elemMatch"].all? do |k, v|
            Matchable.matcher(sub_document, k, v)._matches?(v)
          end
        end
      end
    end
  end
end
