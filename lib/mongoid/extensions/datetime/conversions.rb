# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module DateTime #:nodoc:

      # This module handles DateTime conversions.
      module Conversions

        # Get the value as a datetime.
        #
        # @example Cast to a datetime.
        #   DateTime.get(value)
        #
        # @param [ Date, Time ] value The value to convert.
        #
        # @return [ DateTime ] The converted date.
        #
        # @since 1.0.0
        def get(value)
          super.try(:to_datetime)
        end
      end
    end
  end
end
