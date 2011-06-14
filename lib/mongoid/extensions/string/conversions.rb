# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module String #:nodoc:
      module Conversions #:nodoc:
        extend ActiveSupport::Concern

        # Convert the string to an array with the string in it.
        #
        # @example Convert the string to an array.
        #   "Testing".to_a
        #
        # @return [ Array ] An array with only the string in it.
        #
        # @since 1.0.0
        def to_a
          [ self ]
        end

        module ClassMethods #:nodoc:

          # Return the string.
          #
          # @example Return the string.
          #   String.get("test")
          #
          # @param [ String ] value The string.
          #
          # @return [ String ] The string unmodified.
          #
          # @since 1.0.0
          def get(value)
            value
          end

          # Set the object as a mongo string.
          #
          # @example Cast the object.
          #   String.set("testing")
          #
          # @param [ Object ] value The object to cast.
          #
          # @return [ String ] The object to_s or nil.
          #
          # @since 1.0.0
          def set(value)
            value.to_s unless value.nil?
          end
        end
      end
    end
  end
end
