# encoding: utf-8
module Mongoid #:nodoc:
  module Matchers #:nodoc:
    class In < Default
      # Return true if the attribute is in the values.
      def matches?(value)
        value.values.first.include?(@attribute)
      end
    end
  end
end
