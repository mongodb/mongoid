# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Boolean #:nodoc:

      # This module converts various types of objects to boolean values.
      module Conversions #:nodoc:
        extend ActiveSupport::Concern

        BOOLEAN_MAP = {
          true => true,
          "true" => true,
          "TRUE" => true,
          "1" => true,
          1 => true,
          1.0 => true,
          false => false,
          "false" => false,
          "FALSE" => false,
          "0" => false,
          0 => false,
          0.0 => false
        }

        module ClassMethods #:nodoc

          # Set the boolean from the passed in value.
          #
          # @example Set the boolean.
          #   Boolean.from_bson("1")
          #
          # @param [ String, Integer, true, false ] value The value to cast.
          #
          # @return [ true, false ] The boolean.
          #
          # @since 1.0.0
          def from_bson(value)
            value = BOOLEAN_MAP[value]
            value.nil? ? nil : value
          end

          # Get the boolean value.
          #
          # @example Get the value.
          #   Boolean.try_bson(true)
          #
          # @param [ true, false ] value The value.
          #
          # @return [ true, false ] The passed in value.
          #
          # @since 1.0.0
          def try_bson(value)
            value
          end
        end
      end
    end
  end
end
