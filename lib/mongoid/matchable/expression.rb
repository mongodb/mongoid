# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Matchable

    class Expression
      def initialize(querent)
        @querent = querent
      end

      # The document or attribute value that is being checked for matching
      # the condition/selector.
      attr_reader :querent

      def _matches?(expr)
        unless expr.is_a?(Hash)
          matcher_cls = if expr.is_a?(Regexp)
            Regexp
          else
            Default
          end
          matcher = matcher_cls.new(querent)
          return matcher._matches?(expr)
        end

        expr.each do |key, value|
          # key can be an operator like $and/$eq or a field name.
          if key.is_a?(String) || key.is_a?(Symbol)
            matcher_cls = LOGICAL_MATCHERS[key] || MATCHERS[key]

            if matcher_cls
              # If key is an operator, we are continuing to match
              # the same querent.
              if !matcher_cls.new(querent)._matches?(value)
                return false
              end

              # The match succeeded - continue with the next pair in original
              # selector.
              next
            end
          end

          # If we are here, key is a field name, and value is the condition
          # that the field must match.
          new_querent = Matchable.extract_attribute(querent, key)
          unless Expression.new(new_querent)._matches?(value)
            return false
          end
        end
        true
      end
    end
  end
end
