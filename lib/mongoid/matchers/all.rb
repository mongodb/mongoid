# encoding: utf-8
module Mongoid #:nodoc:
  module Matchers #:nodoc:
    class All < Default
      # Return true if the attribute and first value in the hash are equal.
      def matches?(value)
        @attribute == value.values.first
      end
    end
  end
end
