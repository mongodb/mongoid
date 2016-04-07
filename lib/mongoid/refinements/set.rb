module Mongoid
  module Refinements

    refine Set do

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   set.mongoize
      #
      # @return [ Array ] The object mongoized.
      #
      # @since 6.0.0
      def mongoize
        ::Set.mongoize(self)
      end
    end

    refine Set.singleton_class do

      # Convert the object from its mongo friendly ruby type to this type.
      #
      # @example Demongoize the object.
      #   Set.demongoize([1, 2, 3])
      #
      # @param [ Array ] object The object to demongoize.
      #
      # @return [ Set ] The set.
      #
      # @since 6.0.0
      def demongoize(object)
        ::Set.new(object)
      end

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   Set.mongoize(Set.new([1,2,3]))
      #
      # @param [ Set ] object The object to mongoize.
      #
      # @return [ Array ] The object mongoized.
      #
      # @since 6.0.0
      def mongoize(object)
        object.to_a
      end
    end
  end
end