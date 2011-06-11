# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:

    # This module handles all the generic time conversions.
    module TimeConversions

      # Get the provided value as a time.
      #
      # @example Get the value as a time.
      #   Time.get(Date.today)
      #
      # @param [ Object ] value The time-like object to convert.
      #
      # @return [ Time ] The converted time.
      #
      # @since 1.0.0
      def get(value)
        return nil if value.blank?
        value = value.getlocal unless Mongoid::Config.use_utc?
        if Mongoid::Config.use_activesupport_time_zone?
          time_zone = Mongoid::Config.use_utc? ? 'UTC' : Time.zone
          value = value.in_time_zone(time_zone)
        end
        value
      end

      # Convert the provided object to a UTC time to store in the database.
      #
      # @example Set the time.
      #   Time.set(Date.today)
      #
      # @param [ String, Date, DateTime, Array ] value The object to cast.
      #
      # @return [ Time ] The object as a UTC time.
      #
      # @since 1.0.0
      def set(value)
        return nil if value.blank?
        time = convert_to_time(value)
        strip_milliseconds(time).utc
      end

      protected

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
      # @since 1.0.0
      def strip_milliseconds(time)
        ::Time.at(time.to_i)
      end

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
    end
  end
end
