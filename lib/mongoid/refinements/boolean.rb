module Mongoid
  module Refinements

    refine ::Boolean.singleton_class do

      # Evolve the value into a boolean value stored in MongoDB. Will return
      # true for any of these values: true, t, yes, y, 1, 1.0.
      #
      # @example Evolve the value to a boolean.
      #   Boolean.evolve(true)
      #
      # @param [ Object ] The object to evolve.
      #
      # @return [ true, false ] The boolean value.
      #
      # @since 1.0.0
      def evolve(object)
        __evolve__(object) do |obj|
          obj.to_s =~ (/(true|t|yes|y|1|1.0)$/i) ? true : false
        end
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
        evolve(object)
      end
    end

    refine Mongoid::Boolean.singleton_class do

      # Evolve the value into a boolean value stored in MongoDB. Will return
      # true for any of these values: true, t, yes, y, 1, 1.0.
      #
      # @example Evolve the value to a boolean.
      #   Boolean.evolve(true)
      #
      # @param [ Object ] The object to evolve.
      #
      # @return [ true, false ] The boolean value.
      #
      # @since 1.0.0
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
