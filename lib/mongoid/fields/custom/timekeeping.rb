# encoding: utf-8
module Mongoid #:nodoc:
  module Fields #:nodoc:
    module Custom #:nodoc:

      # This module contains shared behaviour for date conversions.
      module Timekeeping

        # Convert the provided object to a UTC time to store in the database.
        #
        # @example Set the time.
        #   Time.convert_to_time(Date.today)
        #
        # @param [ String, Date, DateTime, Array ] value The object to cast.
        #
        # @return [ Time ] The object as a UTC time.
        #
        # @since 1.0.0
        def convert_to_time(value)
          time = Mongoid::Config.use_activesupport_time_zone? ? ::Time.zone : ::Time
          case value
            when ::String
              time.parse(value)
            when ::DateTime
              time.local(value.year, value.month, value.day, value.hour, value.min, value.sec)
            when ::Date
              time.local(value.year, value.month, value.day)
            when ::Array
              time.local(*value)
            else
              value
          end
        end

        # Strip the milliseconds off the time.
        #
        # @todo Durran: Why is this here? Still need time refactoring.
        #
        # @example Strip.
        #   Time.strip_millseconds(Time.now)
        #
        # @param [ Time ] time The time to strip.
        #
        # @return [ Time ] The time without millis.
        #
        # @since 2.1.0
        def strip_milliseconds(time)
          ::Time.at(time.to_i)
        end
      end
    end
  end
end
