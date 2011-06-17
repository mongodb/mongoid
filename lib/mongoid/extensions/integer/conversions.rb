# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Integer #:nodoc:

      # Handles conversion of integers.
      module Conversions

        # Convert the value to an integer.
        #
        # @example Convert the value.
        #   Integer.mongoize("5")
        #
        # @param [ Numeric, String ] value The value to cast.
        #
        # @return [ Numeric ] The converted value.
        #
        # @since 2.1.0
        def mongoize(value)
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
