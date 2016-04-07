module Mongoid
  module Refinements

    refine Symbol.singleton_class do

      # Convert the object from its mongo friendly ruby type to this type.
      #
      # @example Demongoize the object.
      #   Symbol.demongoize(object)
      #
      # @param [ Object ] object The object to demongoize.
      #
      # @return [ Symbol ] The object.
      #
      # @since 6.0.0
      def demongoize(object)
        object.try(:to_sym)
      end

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   Symbol.mongoize("123.11")
      #
      # @param [ Object ] object The object to mongoize.
      #
      # @return [ Symbol ] The object mongoized.
      #
      # @since 6.0.0
      def mongoize(object)
        demongoize(object)
      end
    end
  end
end