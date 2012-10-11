# encoding: utf-8
module Mongoid
  module Extensions
    module DateTime

      # Mongoize the date time into a time.
      #
      # @example Mongoize the date time.
      #   date_time.__mongoize_time__
      #
      # @return [ Time ] The mongoized time.
      #
      # @since 3.0.0
      def __mongoize_time__
        return self if utc? && Mongoid.use_utc?
        if Mongoid.use_activesupport_time_zone?
          in_time_zone(::Time.zone)
        else
          time = to_time
          time.respond_to?(:getlocal) ? time.getlocal : time
        end
      end

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   date_time.mongoize
      #
      # @return [ Time ] The object mongoized.
      #
      # @since 3.0.0
      def mongoize
        ::DateTime.mongoize(self)
      end

      module ClassMethods

        # Convert the object from its mongo friendly ruby type to this type.
        #
        # @example Demongoize the object.
        #   DateTime.demongoize(object)
        #
        # @param [ Time ] object The time from Mongo.
        #
        # @return [ DateTime ] The object as a date.
        #
        # @since 3.0.0
        def demongoize(object)
          ::Time.demongoize(object).try(:to_datetime)
        end

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   DateTime.mongoize("2012-1-1")
        #
        # @param [ Object ] object The object to convert.
        #
        # @return [ Time ] The object mongoized.
        #
        # @since 3.0.0
        def mongoize(object)
          ::Time.mongoize(object)
        end
      end
    end
  end
end

::DateTime.__send__(:include, Mongoid::Extensions::DateTime)
::DateTime.__send__(:extend, Mongoid::Extensions::DateTime::ClassMethods)
