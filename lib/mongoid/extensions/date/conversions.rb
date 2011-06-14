# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Date #:nodoc:

      # This module handles casting of dates.
      module Conversions

        # Get the value as a date.
        #
        # @example Get the value as a date.
        #   Date.get(value)
        #
        # @param [ Time ] value The time to convert.
        #
        # @return [ Time ] The time as a date.
        #
        # @since 1.0.0
        def get(value)
          return nil if value.blank?
          if Mongoid::Config.use_utc?
            value.to_date
          else
            ::Date.new(value.year, value.month, value.day)
          end
        end

        protected

        # Converts the date to a time to persist.
        #
        # @example Convert the date to a time.
        #   Date.convert_to_time(date)
        #
        # @param [ Date ] value The date to convert.
        #
        # @return [ Time ] The date converted.
        #
        # @since 1.0.0
        def convert_to_time(value)
          value = ::Date.parse(value) if value.is_a?(::String)
          value = ::Date.civil(*value) if value.is_a?(::Array)
          ::Time.utc(value.year, value.month, value.day)
        end
      end
    end
  end
end
