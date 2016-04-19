module Mongoid
  module Refinements

    refine Date do

      # Convert the date into a time.
      #
      # @example Convert the date to a time.
      #   date.__mongoize_time__
      #
      # @return [ Time ] The converted time.
      #
      # @since 6.0.0
      def mongoize_time
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
      # @since 6.0.0
      def mongoize
        ::Date.mongoize(self)
      end

      # Evolve the date into a mongo friendly time, UTC midnight.
      #
      # @example Evolve the date.
      #   date.__evolve_date__
      #
      # @return [ Time ] The date as a UTC time at midnight.
      #
      # @since 1.0.0
      def __evolve_date__
        ::Time.utc(year, month, day, 0, 0, 0, 0)
      end

      # Evolve the date into a time, which is always in the local timezone.
      #
      # @example Evolve the date.
      #   date.__evolve_time__
      #
      # @return [ Time ] The date as a local time.
      #
      # @since 1.0.0
      def __evolve_time__
        ::Time.local(year, month, day)
      end
    end

    refine Date.singleton_class do

      # Constant for epoch - used when passing invalid times.
      DATE_EPOCH = ::Date.new(1970, 1, 1).freeze

      # Convert the object from its mongo friendly ruby type to this type.
      #
      # @example Demongoize the object.
      #   Date.demongoize(object)
      #
      # @param [ Time ] object The time from Mongo.
      #
      # @return [ Date ] The object as a date.
      #
      # @since 6.0.0
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
      # @since 6.0.0
      def mongoize(object)
        unless object.blank?
          begin
            time = object.mongoize_time
            ::Time.utc(time.year, time.month, time.day)
          rescue ArgumentError
            DATE_EPOCH
          end
        end
      end

      # Evolve the object to an date.
      #
      # @example Evolve dates.
      #   Date.evolve(Date.new(1990, 1, 1))
      #
      # @example Evolve string dates.
      #   Date.evolve("1990-1-1")
      #
      # @example Evolve date ranges.
      #   Date.evolve(Date.new(1990, 1, 1)..Date.new(1990, 1, 4))
      #
      # @param [ Object ] object The object to evolve.
      #
      # @return [ Time ] The evolved date.
      #
      # @since 1.0.0
      def evolve(object)
        if object.is_a?(DateTime)
          object.__evolve_time__
        else
          object.__evolve_date__
        end
      end
    end
  end
end
