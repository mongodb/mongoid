# frozen_string_literal: true

module Mongoid
  module Extensions
    module Time

      # Mongoizes a Time into a time.
      #
      # Time always mongoize into Time instances
      # (which are themselves).
      #
      # @return [ Time ] self.
      def __mongoize_time__
        self
      end

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   time.mongoize
      #
      # @return [ Time | nil ] The object mongoized or nil.
      def mongoize
        ::Time.mongoize(self)
      end

      module ClassMethods

        # Get the configured time to use when converting - either the time zone
        # or the time.
        #
        # @example Get the configured time.
        #   ::Time.configured
        #
        # @return [ Time ] The configured time.
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
        # @return [ Time | nil ] The object mongoized or nil.
        def mongoize(object)
          return if object.nil?
          begin
            time = object.__mongoize_time__
            if time.acts_like?(:time)
              if object.respond_to?(:sec_fraction)
                ::Time.at(time.to_i, object.sec_fraction * 10**6).utc
              elsif time.respond_to?(:subsec)
                ::Time.at(time.to_i, time.subsec * 10**6).utc
              else
                ::Time.at(time.to_i, time.usec).utc
              end
            end
          rescue ArgumentError
            nil
          end
        end
      end
    end
  end
end

::Time.__send__(:include, Mongoid::Extensions::Time)
::Time.extend(Mongoid::Extensions::Time::ClassMethods)
