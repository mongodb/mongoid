module Mongoid

  module Refinements

    refine BigDecimal do

      # Convert the big decimal to an $inc-able value.
      #
      # @example Convert the big decimal.
      #   bd.to_inc
      #
      # @return [ Float ] The big decimal as a float.
      #
      # @since 6.0.0
      def to_inc
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
      # @since 6.0.0
      def mongoize
        to_s
      end
    end

    refine BigDecimal.singleton_class do

      # Convert the object from its mongo friendly ruby type to this type.
      #
      # @example Demongoize the object.
      #   Object.demongoize(object)
      #
      # @param [ Object ] object The object to demongoize.
      #
      # @return [ Object ] The object.
      #
      # @since 6.0.0
      def demongoize(object)
        if object
          object.numeric? ? ::BigDecimal.new(object.to_s) : object
        end
      end

      # Mongoize an object of any type to how it's stored in the db as a big
      # decimal.
      #
      # @example Mongoize the object.
      #   BigDecimal.mongoize(123)
      #
      # @param [ Object ] object The object to Mongoize
      #
      # @return [ String ] The mongoized object.
      #
      # @since 6.0.0
      def mongoize(object)
        object ? object.to_s : object
      end
    end
  end
end