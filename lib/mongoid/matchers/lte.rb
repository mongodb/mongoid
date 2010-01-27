# encoding: utf-8
module Mongoid #:nodoc:
  module Matchers #:nodoc:
    class Lte < Default
      # Return true if the attribute is less than or equal to the value.
      def matches?(value)
        determine(value, :<=)
      end
    end
  end
end
