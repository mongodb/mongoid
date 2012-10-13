# encoding: utf-8
module Mongoid
  module Extensions
    module TimeWithZone

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
        ::ActiveSupport::TimeWithZone.mongoize(self)
      end

      module ClassMethods

        # Convert the object from its mongo friendly ruby type to this type.
        #
        # @example Demongoize the object.
        #   TimeWithZone.demongoize(object)
        #
        # @param [ Time ] object The time from Mongo.
        #
        # @return [ TimeWithZone ] The object as a date.
        #
        # @since 3.0.0
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
        # @since 3.0.0
        def mongoize(object)
          ::Time.mongoize(object)
        end
      end
    end
  end
end

::ActiveSupport::TimeWithZone.__send__(:include, Mongoid::Extensions::TimeWithZone)
::ActiveSupport::TimeWithZone.__send__(:extend, Mongoid::Extensions::TimeWithZone::ClassMethods)
