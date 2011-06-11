# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Integer #:nodoc:

      # Handles conversion of integers.
      module Conversions

        # Get the integer.
        #
        # @example Get the integer.
        #   Integer.get(1)
        #
        # @param [ Integer ] value The value to return.
        #
        # @return [ Integer ] The unmodified value.
        #
        # @since 1.0.0
        def get(value)
          value
        end

        # Convert the value to an integer.
        #
        # @example Convert the value.
        #   Integer.set("5")
        #
        # @param [ Numeric, String ] value The value to cast.
        #
        # @return [ Numeric ] The converted value.
        #
        # @since 1.0.0
        def set(value)
          return nil if value.blank?
          begin
            value.to_s =~ /\./ ? Float(value) : Integer(value)
          rescue
            value
          end
        end
      end
    end
  end
end
