module Mongoid
  module Refinements

    refine DateTime do

      # Mongoize the date time into a time.
      #
      # @example Mongoize the date time.
      #   date_time.mongoize_time
      #
      # @return [ Time ] The mongoized time.
      #
      # @since 6.0.0
      def mongoize_time
        return to_time if utc? && Mongoid.use_utc?
        if Mongoid.use_activesupport_time_zone?
          in_time_zone(::Time.zone).to_time
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
      # @since 6.0.0
      def mongoize
        ::DateTime.mongoize(self)
      end

      # Evolve the date time into a mongo friendly UTC time.
      #
      # @example Evolve the date time.
      #   date_time.__evolve_time__
      #
      # @return [ Time ] The converted time in UTC.
      #
      # @since 1.0.0
      def __evolve_time__
        usec = strftime("%6N").to_f
        if utc?
          ::Time.utc(year, month, day, hour, min, sec, usec)
        else
          ::Time.local(year, month, day, hour, min, sec, usec).utc
        end
      end
    end

    refine DateTime.singleton_class do

      # Convert the object from its mongo friendly ruby type to this type.
      #
      # @example Demongoize the object.
      #   DateTime.demongoize(object)
      #
      # @param [ Time ] object The time from Mongo.
      #
      # @return [ DateTime ] The object as a date.
      #
      # @since 6.0.0
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
      # @since 6.0.0
      def mongoize(object)
        ::Time.mongoize(object)
      end

      # Evolve the object to an date.
      #
      # @example Evolve dates.
      #
      # @example Evolve string dates.
      #
      # @example Evolve date ranges.
      #
      # @param [ Object ] object The object to evolve.
      #
      # @return [ Time ] The evolved date time.
      #
      # @since 1.0.0
      def evolve(object)
        object.__evolve_time__
      end
    end
  end
end
