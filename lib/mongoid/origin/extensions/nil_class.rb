# encoding: utf-8
module Origin
  module Extensions

    # This module contains additional nil behaviour.
    module NilClass

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

::NilClass.__send__(:include, Origin::Extensions::NilClass)
