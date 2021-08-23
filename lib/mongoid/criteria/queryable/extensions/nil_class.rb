# frozen_string_literal: true

module Mongoid
  class Criteria
    module Queryable
      module Extensions

        # This module contains additional nil behavior.
        module NilClass

          # Add this object to nil.
          #
          # @example Add the object to a nil value.
          #   nil.__add__([ 1, 2, 3 ])
          #
          # @param [ Object ] object The object to add.
          #
          # @return [ Object ] The provided object.
          def __add__(object); object; end

          # Add this object to nil.
          #
          # @example Add the object to a nil value.
          #   nil.__expanded__([ 1, 2, 3 ])
          #
          # @param [ Object ] object The object to expanded.
          #
          # @return [ Object ] The provided object.
          def __expanded__(object); object; end

          # Evolve the nil into a date or time.
          #
          # @example Evolve the nil.
          #   nil.__evolve_time__
          #
          # @return [ nil ] nil.
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
          def __intersect__(object); object; end

          # Add this object to nil.
          #
          # @example Add the object to a nil value.
          #   nil.__override__([ 1, 2, 3 ])
          #
          # @param [ Object ] object The object to override.
          #
          # @return [ Object ] The provided object.
          def __override__(object); object; end

          # Add this object to nil.
          #
          # @example Add the object to a nil value.
          #   nil.__union__([ 1, 2, 3 ])
          #
          # @param [ Object ] object The object to union.
          #
          # @return [ Object ] The provided object.
          def __union__(object); object; end
        end
      end
    end
  end
end

::NilClass.__send__(:include, Mongoid::Criteria::Queryable::Extensions::NilClass)
