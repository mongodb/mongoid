module Mongoid
  module Refinements

    refine NilClass do

      # Try to form a setter from this object.
      #
      # @example Try to form a setter.
      #   object.setter
      #
      # @return [ nil ] Always nil.
      #
      # @since 6.0.0
      def setter; self; end

      # Get the name of a nil collection.
      #
      # @example Get the nil name.
      #   nil.collectionize
      #
      # @return [ String ] A blank string.
      #
      # @since 6.0.0
      def collectionize
        to_s.collectionize
      end

      # Add this object to nil.
      #
      # @example Add the object to a nil value.
      #   nil.__add__([ 1, 2, 3 ])
      #
      # @param [ Object ] object The object to add.
      #
      # @return [ Object ] The provided object.
      #
      # @since 1.0.0
      def __add__(object); object; end

      # Add this object to nil.
      #
      # @example Add the object to a nil value.
      #   nil.__expanded__([ 1, 2, 3 ])
      #
      # @param [ Object ] object The object to expanded.
      #
      # @return [ Object ] The provided object.
      #
      # @since 1.0.0
      def __expanded__(object); object; end

      # Evolve the nil into a date or time.
      #
      # @example Evolve the nil.
      #   nil.__evolve_time__
      #
      # @return [ nil ] nil.
      #
      # @since 1.0.0
      def __evolve_time__; self; end
      alias :__evolve_date__ :__evolve_time__

      # Add this object to nil.
      #
      # @example Add the object to a nil value.
      #   nil.__intersect__([ 1, 2, 3 ])
      #
      # @param [ Object ] object The object to intersect.
      #
      # @return [ Object ] The provided object.
      #
      # @since 1.0.0
      def __intersect__(object); object; end

      # Add this object to nil.
      #
      # @example Add the object to a nil value.
      #   nil.__override__([ 1, 2, 3 ])
      #
      # @param [ Object ] object The object to override.
      #
      # @return [ Object ] The provided object.
      #
      # @since 1.0.0
      def __override__(object); object; end

      # Add this object to nil.
      #
      # @example Add the object to a nil value.
      #   nil.__union__([ 1, 2, 3 ])
      #
      # @param [ Object ] object The object to union.
      #
      # @return [ Object ] The provided object.
      #
      # @since 1.0.0
      def __union__(object); object; end
    end
  end
end
