# frozen_string_literal: true
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
        condition = condition_value(value, '$elemMatch')

        if !@attribute.is_a?(Array) || !condition.kind_of?(Hash)
          return false
        end

        return @attribute.any? do |sub_document|
          condition.all? do |k, v|
            if v.try(:first).try(:[],0) == "$not".freeze || v.try(:first).try(:[],0) == :$not
              !Matchable.matcher(sub_document, k, v.first[1])._matches?(v.first[1])
            else
              Matchable.matcher(sub_document, k, v)._matches?(v)
            end
          end
        end
      end
    end
  end
end
