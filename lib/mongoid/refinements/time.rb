module Mongoid
  module Refinements

    refine Time do

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   time.mongoize
      #
      # @return [ Time ] The object mongoized.
      #
      # @since 6.0.0
      def mongoize
        ::Time.mongoize(self)
      end

      # Evolve the time as a date, UTC midnight.
      #
      # @example Evolve the time to a date query format.
      #   time.__evolve_date__
      #
      # @return [ Time ] The date at midnight UTC.
      #
      # @since 1.0.0
      def __evolve_date__
        ::Time.utc(year, month, day, 0, 0, 0, 0)
      end

      # Evolve the time into a utc time.
      #
      # @example Evolve the time.
      #   time.__evolve_time__
      #
      # @return [ Time ] The time in UTC.
      #
      # @since 1.0.0
      def __evolve_time__
        utc
      end
    end

    refine Time.singleton_class do

      # Constant for epoch - used when passing invalid times.
      TIME_EPOCH = ::Time.utc(1970, 1, 1, 0, 0, 0).freeze

      # Get the configured time to use when converting - either the time zone
      # or the time.
      #
      # @example Get the configured time.
      #   ::Time.configured
      #
      # @retun [ Time ] The configured time.
      #
      # @since 6.0.0
      def configured
        Mongoid.use_activesupport_time_zone? ? (::Time.zone || ::Time) : ::Time
      end

      # Convert the object from its mongo friendly ruby type to this type.
      #
      # @example Demongoize the object.
      #   Time.demongoize(object)
      #
      # @param [ Time ] object The time from Mongo.
      #
      # @return [ Time ] The object as a date.
      #
      # @since 6.0.0
      def demongoize(object)
        return nil if object.blank?
        object = object.getlocal unless Mongoid::Config.use_utc?
        if Mongoid::Config.use_activesupport_time_zone?
          object = object.in_time_zone(Mongoid.time_zone)
        end
        object
      end

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   Time.mongoize("2012-1-1")
      #
      # @param [ Object ] object The object to mongoize.
      #
      # @return [ Time ] The object mongoized.
      #
      # @since 6.0.0
      def mongoize(object)
        return nil if object.blank?
        begin
          time = object.mongoize_time
          if object.respond_to?(:sec_fraction)
            ::Time.at(time.to_i, object.sec_fraction * 10**6).utc
          elsif time.respond_to?(:subsec)
            ::Time.at(time.to_i, time.subsec * 10**6).utc
          else
            ::Time.at(time.to_i, time.usec).utc
          end
        rescue ArgumentError
          TIME_EPOCH
        end
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