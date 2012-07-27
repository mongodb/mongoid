# encoding: utf-8
module Mongoid
  module Extensions
    module BigDecimal

      # Convert the big decimal to an $inc-able value.
      #
      # @example Convert the big decimal.
      #   bd.__to_inc__
      #
      # @return [ Float ] The big decimal as a float.
      #
      # @since 3.0.3
      def __to_inc__
        to_f
      end

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
          if object
            object.numeric? ? ::BigDecimal.new(object.to_s) : object
          end
        end
      end
    end
  end
end

::BigDecimal.__send__(:include, Mongoid::Extensions::BigDecimal)
::BigDecimal.__send__(:extend, Mongoid::Extensions::BigDecimal::ClassMethods)
