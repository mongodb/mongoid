# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Binary #:nodoc:

      # This module handles conversion of binary data.
      module Conversions

        # Get the value from the db hash.
        #
        # @example Get the value.
        #   Binary.try_bson(binary)
        #
        # @param [ Binary ] value The binary.
        #
        # @return [ Binary ] The passed in value.
        #
        # @since 1.0.0
        def try_bson(value)
          value
        end

        # Set the value in the db hash.
        #
        # @example Set the value.
        #   Binary.from_bson(binary)
        #
        # @param [ Binary ] value The binary.
        #
        # @return [ Binary ] The passed in value.
        #
        # @since 1.0.0
        def from_bson(value)
          value
        end
      end
    end
  end
end
