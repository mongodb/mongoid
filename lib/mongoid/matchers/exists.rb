# encoding: utf-8
module Mongoid #:nodoc:
  module Matchers #:nodoc:
    class Exists < Default
      # Return true if the attribute exists and checking for existence or
      # return true if the attribute does not exist and checking for
      # non-existence.
      def matches?(value)
        @attribute.nil? != value.values.first
      end
    end
  end
end
