# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module Extensions

    # Adds type-casting behavior to ActiveSupport::TimeWithZone class.
    module TimeWithZone

      # Mongoizes an ActiveSupport::TimeWithZone into a time.
      #
      # TimeWithZone always mongoize into TimeWithZone instances
      # (which are themselves).
      #
      # @return [ ActiveSupport::TimeWithZone ] self.
      def __mongoize_time__
        self
      end

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   date_time.mongoize
      #
      # @return [ Time ] The object mongoized.
      def mongoize
        ::ActiveSupport::TimeWithZone.mongoize(self)
      end

      # This code is copied from Time class extension in bson-ruby gem. It
      # should be removed from here when the minimum BSON version is 5+.
      # See https://jira.mongodb.org/browse/MONGOID-5491.
      def _bson_to_i
        return super if defined?(super)
        # Workaround for JRuby's #to_i rounding negative timestamps up
        # rather than down (https://github.com/jruby/jruby/issues/6104)
        if BSON::Environment.jruby?
          (self - usec.to_r/1000000).to_i
        else
          to_i
        end
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
        def demongoize(object)
          ::Time.demongoize(object).try(:in_time_zone)
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
        def mongoize(object)
          ::Time.mongoize(object)
        end
      end
    end
  end
end

::ActiveSupport::TimeWithZone.__send__(:include, Mongoid::Extensions::TimeWithZone)
::ActiveSupport::TimeWithZone.extend(Mongoid::Extensions::TimeWithZone::ClassMethods)
