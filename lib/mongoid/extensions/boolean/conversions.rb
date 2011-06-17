# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Boolean #:nodoc:

      # This module converts various types of objects to boolean values.
      module Conversions #:nodoc:

        # Set the boolean from the passed in value.
        #
        # @example Set the boolean.
        #   Boolean.mongoize("1")
        #
        # @param [ String, Integer, true, false ] value The value to cast.
        #
        # @return [ true, false ] The boolean.
        #
        # @since 2.1.0
        def mongoize(value)
          return nil unless value
          value.to_s.match(/(true|t|yes|y|1)$/i) != nil
        end
      end
    end
  end
end
