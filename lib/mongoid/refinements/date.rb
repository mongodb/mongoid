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
    end
  end
end