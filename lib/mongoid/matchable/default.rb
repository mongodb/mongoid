# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Matchable

    # Contains all the default behavior for checking for matching documents
    # given MongoDB expressions.
    class Default

      attr_accessor :attribute, :document

      # Creating a new matcher only requires the value.
      #
      # @example Create a new matcher.
      #   Default.new("attribute")
      #
      # @param [ Object ] attribute The current attribute to check against.
      #
      # @since 1.0.0
      def initialize(attribute, document = nil)
        @attribute, @document = attribute, document
      end

      # Return true if the attribute and value are equal, or if it is an array
      # if the value is included.
      #
      # @example Does this value match?
      #   default._matches?("value")
      #
      # @param [ Object ] value The value to check if it matches.
      #
      # @return [ true, false ] True if matches, false if not.
      #
      # @since 1.0.0
      def _matches?(value)
        attribute.is_a?(Array) && !value.is_a?(Array) ? attribute.any? { |_attribute| value === _attribute } : value === attribute
      end

      protected

      # Convenience method for getting the first value in a hash.
      #
      # @example Get the first value.
      #   matcher.first(:test => "value")
      #
      # @param [ Hash ] hash The hash to pull from.
      #
      # @return [ Object ] The first value.
      #
      # @since 1.0.0
      def first(hash)
        hash.values.first
      end

      # If object exists then compare the two, otherwise return false
      #
      # @example Determine if we can compare.
      #   matcher.determine("test", "$in")
      #
      # @param [ Object ] value The value to compare with.
      # @param [ Symbol, String ] operator The comparison operation.
      #
      # @return [ true, false ] The comparison or false.
      #
      # @since 1.0.0
      def determine(value, operator)
        attribute.__array__.any? {|attr|
          attr ? attr.send(operator, first(value)) : false
        }
      end

      # Convenience method for checking _matches? on a Document or a Hash.
      #
      # @example Does the document of type Document or Hash match?
      #   recursive_matches?(default, "a", 1)
      #   recursive_matches?(:a => 1, "b", 2)
      #
      # @param [ Document, Hash ] document The object of type Document or Hash to call _matches? on
      # @param [ String ] key The key
      # @param [ Object ] value The value to check if it matches.
      #
      # @return [ true, false ] True if matches, false if not.
      #
      # @since 7.0.4
      def recursive_matches?(document, key, value)
        if document.is_a?(Document)
          document._matches?(key => value)
        else
          Matchable.matcher(document, key, value)._matches?(value)
        end
      end
    end
  end
end
