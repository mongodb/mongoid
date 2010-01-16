# encoding: utf-8
module Mongoid #:nodoc:
  module Matchers #:nodoc:
    class Lt < Default
      # Return true if the attribute is less than the value.
      def matches?(value)
        @attribute ? @attribute < first(value) : false
      end
    end
  end
end
