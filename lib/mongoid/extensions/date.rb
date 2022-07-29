# frozen_string_literal: true

module Mongoid
  module Extensions
    module Date

      # Convert the date into a time.
      #
      # @example Convert the date to a time.
      #   Date.new(2018, 11, 1).__mongoize_time__
      #   # => Thu, 01 Nov 2018 00:00:00 EDT -04:00
      #
      # @return [ Time | ActiveSupport::TimeWithZone ] Local time in the
      #   configured default time zone corresponding to local midnight of
      #   this date.
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
        # @return [ Date | nil ] The object as a date or nil.
        def demongoize(object)
          return if object.nil?
          if object.is_a?(String)
            object = begin
              object.__mongoize_time__
            rescue ArgumentError
              nil
            end
          end

          if object.acts_like?(:time) || object.acts_like?(:date)
            ::Date.new(object.year, object.month, object.day)
          end
        end

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   Date.mongoize("2012-1-1")
        #
        # @param [ Object ] object The object to mongoize.
        #
        # @return [ Time | nil ] The object mongoized or nil.
        def mongoize(object)
          return if object.blank?
          begin
            if object.is_a?(String)
              # https://jira.mongodb.org/browse/MONGOID-4460
              time = ::Time.parse(object)
            else
              time = object.__mongoize_time__
            end
          rescue ArgumentError
            nil
          end
          if time.acts_like?(:time)
            ::Time.utc(time.year, time.month, time.day)
          end
        end
      end
    end
  end
end

::Date.__send__(:include, Mongoid::Extensions::Date)
::Date.extend(Mongoid::Extensions::Date::ClassMethods)
