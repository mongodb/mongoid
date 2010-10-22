# encoding: utf-8
module Mongoid #:nodoc:
  module Matchers #:nodoc:
    class Default
      # Creating a new matcher only requires the value.
      def initialize(attribute)
        @attribute = attribute
      end
      # Return true if the attribute and value are equal.
      def matches?(value)
        @attribute.is_a?(Array) && value.is_a?(String) ?
          @attribute.include?(value) : value === @attribute
      end

      protected
      # Return the first value in the hash.
      def first(value)
        value.values.first
      end

      # If object exists then compare, else return false
      def determine(value, operator)
        @attribute ? @attribute.send(operator, first(value)) : false
      end
    end
  end
end
