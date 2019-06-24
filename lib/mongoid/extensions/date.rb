# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Extensions
    module Date

      # Constant for epoch - used when passing invalid times.
      #
      # @deprecated No longer used as a return value from #mongoize passed
      #   an invalid date string.
      EPOCH = ::Date.new(1970, 1, 1)

      # Convert the date into a time.
      #
      # @example Convert the date to a time.
      #   Date.new(2018, 11, 1).__mongoize_time__
      #   # => Thu, 01 Nov 2018 00:00:00 EDT -04:00
      #
      # @return [ Time | ActiveSupport::TimeWithZone ] Local time in the
      #   configured default time zone corresponding to local midnight of
      #   this date.
      #
      # @since 3.0.0
      def __mongoize_time__
        ::Time.configured.local(year, month, day)
      end

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   date.mongoize
      #
      # @return [ Time ] The object mongoized.
      #
      # @since 3.0.0
      def mongoize
        ::Date.mongoize(self)
      end

      module ClassMethods

        # Convert the object from its mongo friendly ruby type to this type.
        #
        # @example Demongoize the object.
        #   Date.demongoize(object)
        #
        # @param [ Time ] object The time from Mongo.
        #
        # @return [ Date ] The object as a date.
        #
        # @since 3.0.0
        def demongoize(object)
          ::Date.new(object.year, object.month, object.day) if object
        end

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   Date.mongoize("2012-1-1")
        #
        # @param [ Object ] object The object to mongoize.
        #
        # @return [ Time ] The object mongoized.
        #
        # @since 3.0.0
        def mongoize(object)
          unless object.blank?
            begin
              if object.is_a?(String)
                # https://jira.mongodb.org/browse/MONGOID-4460
                time = ::Time.parse(object)
              else
                time = object.__mongoize_time__
              end
              ::Time.utc(time.year, time.month, time.day)
            rescue ArgumentError
              nil
            end
          end
        end
      end
    end
  end
end

::Date.__send__(:include, Mongoid::Extensions::Date)
::Date.extend(Mongoid::Extensions::Date::ClassMethods)
