# encoding: utf-8
require "bigdecimal"

module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module BigDecimal #:nodoc:
      module Conversions #:nodoc:
        # Get the string as a +BigDecimal+
        def get(value)
          value ? ::BigDecimal.new(value) : value
        end
        # Set the value in the hash as a string.
        def set(value)
          value ? value.to_s : value
        end
      end
    end
  end
end
