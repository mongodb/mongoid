# encoding: utf-8
module Origin
  module Extensions

    # This module contains additional range behaviour.
    module Range

      # Get the range as an array.
      #
      # @example Get the range as an array.
      #   1...3.__array__
      #
      # @return [ Array ] The range as an array.
      #
      # @since 1.0.0
      def __array__
        to_a
      end

      # Convert the range to a min/max mongo friendly query for dates.
      #
      # @example Evolve the range.
      #   (11231312..213123131).__evolve_date__
      #
      # @return [ Hash ] The min/max range query with times at midnight.
      #
      # @since 1.0.0
      def __evolve_date__
        { "$gte" => min.__evolve_date__, "$lte" => max.__evolve_date__ }
      end

      # Convert the range to a min/max mongo friendly query for times.
      #
      # @example Evolve the range.
      #   (11231312..213123131).__evolve_date__
      #
      # @return [ Hash ] The min/max range query with times.
      #
      # @since 1.0.0
      def __evolve_time__
        { "$gte" => min.__evolve_time__, "$lte" => max.__evolve_time__ }
      end

      module ClassMethods

        # Evolve the range. This will transform it into a $gte/$lte selection.
        #
        # @example Evolve the range.
        #   Range.evolve(1..3)
        #
        # @param [ Range ] object The range to evolve.
        #
        # @return [ Hash ] The range as a gte/lte criteria.
        #
        # @since 1.0.0
        def evolve(object)
          return object unless object.is_a?(::Range)
          { "$gte" => object.min, "$lte" => object.max }
        end
      end
    end
  end
end

::Range.__send__(:include, Origin::Extensions::Range)
::Range.__send__(:extend, Origin::Extensions::Range::ClassMethods)
