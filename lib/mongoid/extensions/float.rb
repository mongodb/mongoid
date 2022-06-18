# frozen_string_literal: true

module Mongoid
  module Extensions
    module Float

      # Converts the float into a time as the number of seconds since the epoch.
      #
      # @example Convert the float into a time.
      #   1335532685.117847.__mongoize_time__
      #
      # @return [ Time | ActiveSupport::TimeWithZone ] The time.
      def __mongoize_time__
        ::Time.configured.at(self)
      end

      # Is the float a number?
      #
      # @example Is the object a number?.
      #   object.numeric?
      #
      # @return [ true ] Always true.
      def numeric?
        true
      end

      module ClassMethods

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   Float.mongoize("123.11")
        #
        # @param [ Object ] object The object to mongoize.
        #
        # @return [ String ] The object mongoized.
        def mongoize(object)
          return if object.nil?
          return if object.is_a?(String) && object.blank?
          if object.numeric?
            object.to_f
          else
            raise Errors::InvalidValue.new(self, object)
          end
        end
        alias :demongoize :mongoize
      end
    end
  end
end

::Float.__send__(:include, Mongoid::Extensions::Float)
::Float.extend(Mongoid::Extensions::Float::ClassMethods)
