# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Float #:nodoc:

      # Converts values to and from floats.
      module Conversions

        # Get the value.
        #
        # @example Get the float value.
        #   Float.try_bson(1.0222)
        #
        # @param [ Float ] value The float.
        #
        # @return [ Float ] The passed in value.
        #
        # @since 1.0.0
        def try_bson(value)
          value
        end

        # Cast the value to a float.
        #
        # @example Cast the value.
        #   Float.from_bson("1.02")
        #
        # @param [ String, Float ] value The value to cast.
        #
        # @return [ Float ] The converted value.
        #
        # @since 1.0.0
        def from_bson(value)
          return nil if value.blank?
          begin
            Float(value)
          rescue ArgumentError => e
            value
          end
        end
      end
    end
  end
end
