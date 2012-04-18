# encoding: utf-8
module Mongoid
  module Extensions
    module BigDecimal

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   object.mongoize
      #
      # @return [ Object ] The object.
      #
      # @since 3.0.0
      def mongoize
        to_s
      end

      module ClassMethods

        # Convert the object from it's mongo friendly ruby type to this type.
        #
        # @example Demongoize the object.
        #   Object.demongoize(object)
        #
        # @param [ Object ] object The object to demongoize.
        #
        # @return [ Object ] The object.
        #
        # @since 3.0.0
        def demongoize(object)
          object ? ::BigDecimal.new(object) : object
        end

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   BigDecimal.mongoize("123.11")
        #
        # @return [ String ] The object mongoized.
        #
        # @since 3.0.0
        def mongoize(object)
          object.mongoize
        end
      end
    end
  end
end

::BigDecimal.__send__(:include, Mongoid::Extensions::BigDecimal)
::BigDecimal.__send__(:extend, Mongoid::Extensions::BigDecimal::ClassMethods)
