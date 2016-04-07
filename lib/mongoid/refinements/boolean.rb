module Mongoid
  module Refinements

    refine Mongoid::Boolean.singleton_class do

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   Boolean.evolve("123.11")
      #
      # @return [ String ] The object evolved.
      #
      # @since 6.0.0
      def evolve(object)
        ::Boolean.evolve(object)
      end

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   Boolean.mongoize("123.11")
      #
      # @return [ String ] The object mongoized.
      #
      # @since 6.0.0
      def mongoize(object)
        ::Boolean.evolve(object)
      end
    end
  end
end