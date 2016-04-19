module Mongoid
  module Refinements

    refine ActiveSupport::TimeWithZone do

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
        ::ActiveSupport::TimeWithZone.mongoize(self)
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

    refine ActiveSupport::TimeWithZone.singleton_class do

      # Convert the object from its mongo friendly ruby type to this type.
      #
      # @example Demongoize the object.
      #   TimeWithZone.demongoize(object)
      #
      # @param [ Time ] object The time from Mongo.
      #
      # @return [ TimeWithZone ] The object as a date.
      #
      # @since 6.0.0
      def demongoize(object)
        return nil if object.blank?
        ::Time.demongoize(object).in_time_zone
      end

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   TimeWithZone.mongoize("2012-1-1")
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
