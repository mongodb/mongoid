# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Matchable

    class ElemMatch < Default

      # Returns true the attribute is an array with at least one element
      # that matches the condition in the value.
      #
      # Value must be a one-element hash with the key of $elemMatch
      # (string or symbol), and the value being an $elemMatch condition, as
      # specified in
      # https://docs.mongodb.com/manual/reference/operator/query/elemMatch/.
      # In particular, the condition can be a hash of key-value pairs of
      # literal values which the attribute's elements will be directly
      # compared to, or condition can be a complex condition containing e.g.
      # $and/$or/$nor logical operators.
      #
      # @example Do the values match?
      #   matcher._matches?({"$elemMatch" => {"a" => 1, "b" => 2}})
      #
      # @param [ Hash ] value The values to check.
      #
      # @return [ true, false ] If the attribute matches the value.
      def _matches?(value)
        condition = condition_value(value, '$elemMatch')

        if !attribute.is_a?(Array) || !condition.is_a?(Hash)
          return false
        end

        return attribute.any? do |sub_document|
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
