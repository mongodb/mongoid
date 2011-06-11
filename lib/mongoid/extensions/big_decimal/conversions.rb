# encoding: utf-8
require "bigdecimal"

module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module BigDecimal #:nodoc:

      # This module converts to and from big decimals.
      module Conversions

        # Get the string as a +BigDecimal+.
        #
        # @example Get the cast value.
        #   BigDecimal.get("2.223123414")
        #
        # @param [ String ] value The string to convert.
        #
        # @return [ BigDecimal, nil ] The cast value or nil.
        #
        # @since 1.0.0
        def get(value)
          value ? ::BigDecimal.new(value) : value
        end

        # Set the value in the hash as a string.
        #
        # @example Set the value.
        #   BigDecimal.set(decimal)
        #
        # @param [ BigDecimal ] value The number to stringify.
        #
        # @return [ String, nil ] The value as a string or nil.
        #
        # @since 1.0.0
        def set(value)
          value ? value.to_s : value
        end
      end
    end
  end
end
