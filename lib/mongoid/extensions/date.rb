# encoding: utf-8
module Mongoid
  module Extensions
    module Date

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   Date.mongoize("2012-1-1")
      #
      # @return [ String ] The object mongoized.
      #
      # @since 3.0.0
      def mongoize
        ::Date.mongoize(self)
      end

      module ClassMethods

        # Convert the object from it's mongo friendly ruby type to this type.
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
          ::Date.new(object.year, object.month, object.day)
        end

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   Date.mongoize("2012-1-1")
        #
        # @param [ Object ] object The object to mongoize.
        #
        # @return [ String ] The object mongoized.
        #
        # @since 3.0.0
        def mongoize(object)
          evolve(object)
        end
      end
    end
  end
end

::Date.__send__(:include, Mongoid::Extensions::Date)
::Date.__send__(:extend, Mongoid::Extensions::Date::ClassMethods)
