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

      # Checks whether the attribute matches the value, using the default
      # MongoDB matching logic (i.e., when no operator is specified in the
      # criteria).
      #
      # If attribute and value are both of basic types like string or number,
      # this method returns true if and only if the attribute equals the value.
      #
      # Value can also be of a type like Regexp or Range which defines
      # more complex matching/inclusion behavior via the === operator.
      # If so, and attribute is still of a basic type like string or number,
      # this method returns true if and only if the value's === operator
      # returns true for the attribute. For example, this method returns true
      # if attribute is a string and value is a Regexp and attribute matches
      # the value, of if attribute is a number and value is a Range and
      # the value includes the attribute.
      #
      # If attribute is an array and value is not an array, the checks just
      # described (i.e. the === operator invocation) are performed on each item
      # of the attribute array. If any of the items in the attribute match
      # the value according to the value type's === operator, this method
      # returns true.
      #
      # If attribute and value are both arrays, this method returns true if and
      # only if the arrays are equal (including the order of the elements).
      #
      # @param [ Object ] value The value to check.
      #
      # @return [ true, false ] True if attribute matches the value, false if not.
      #
      # @since 1.0.0
      def _matches?(value)
        if attribute.is_a?(Array) && !value.is_a?(Array)
          attribute.any? { |_attribute| value === _attribute }
        else
          value === attribute
        end
      end

      protected

      # Given a condition, which is a one-element hash consisting of an
      # operator and a value like {'$gt' => 1}, return the value.
      #
      # @example Get the condition value.
      #   matcher.condition_value({'$gt' => 1})
      #   # => 1
      #
      # @param [ Hash ] condition The condition.
      #
      # @return [ Object ] The value of the condition.
      #
      # @since 1.0.0
      def condition_value(condition)
        unless condition.is_a?(Hash)
          raise ArgumentError, 'Condition must be a hash'
        end

        unless condition.length == 1
          raise ArgumentError, 'Condition must have one element'
        end

        condition.values.first
      end

      # Determines whether the attribute value stored in this matcher
      # satisfies the provided condition using the provided operator.
      #
      # For example, given an instance of Gt matcher with the @attribute of
      # 2, the matcher is set up to answer whether the attribute is
      # greater than some input value. This input value is provided in
      # the condition, which could be {"$gt" => 1}, and the operator is
      # provided (somewhat in a duplicate fashion) in the operator argument,
      # in this case :>.
      #
      # @example
      #   matcher = Matchable::Gt.new(2)
      #   matcher.determine({'$gt' => 1}, :>)
      #   # => true
      #
      # @param [ Hash ] condition The condition to evaluate. This must be
      #   a one-element hash; the key is ignored, and the value is passed
      #   as the argument to the operator.
      # @param [ Symbol, String ] operator The comparison operator or method.
      #   The operator is invoked on the attribute stored in the matcher
      #   instance.
      #
      # @return [ true, false ] Result of condition evaluation.
      #
      # @since 1.0.0
      def determine(condition, operator)
        attribute.__array__.any? do |attr|
          attr && attr.send(operator, condition_value(condition))
        end
      end
    end
  end
end
