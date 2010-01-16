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
        @attribute == value
      end

      protected
      def first(value)
        value.values.first
      end
    end
  end
end
