# encoding: utf-8
module Mongoid
  module Extensions
    module Date

      # Constant for epoch - used when passing invalid times.
      EPOCH = ::Date.new(1970, 1, 1)

      # Convert the date into a time.
      #
      # @example Convert the date to a time.
      #   date.__mongoize_time__
      #
      # @return [ Time ] The converted time.
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
              time = object.__mongoize_time__
              ::Time.utc(time.year, time.month, time.day)
            rescue ArgumentError
              EPOCH
            end
          end
        end
      end
    end
  end
end

::Date.__send__(:include, Mongoid::Extensions::Date)
::Date.__send__(:extend, Mongoid::Extensions::Date::ClassMethods)
