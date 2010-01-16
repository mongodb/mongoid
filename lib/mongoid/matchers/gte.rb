# encoding: utf-8
module Mongoid #:nodoc:
  module Matchers #:nodoc:
    class Gte < Default
      # Return true if the attribute is greater than or equal to the value.
      def matches?(value)
        @attribute ? @attribute >= first(value) : false
      end
    end
  end
end
