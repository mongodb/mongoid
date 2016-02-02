# encoding: utf-8
module Origin
  module Extensions

    # This module contains additional object behaviour.
    module Object

      # Combine the two objects using the add strategy.
      #
      # @example Add the object to the array.
      #   [ 1, 2, 3 ].__add__(4)
      #
      # @param [ Object ] object The object to add.
      #
      # @return [ Object ] The result of the add.
      #
      # @since 1.0.0
      def __add__(object)
        (object == self) ? self : [ self, object ].flatten.uniq
      end

      # Merge this object into the provided array.
      #
      # @example Merge the object into the array.
      #   4.__add_from_array__([ 1, 2 ])
      #
      # @param [ Array ] value The array to add to.
      #
      # @return [ Array ] The merged object.
      #
      # @since 1.0.0
      def __add_from_array__(array)
        array.concat(Array(self)).uniq
      end

      # Combine the two objects using the intersect strategy.
      #
      # @example Add the object to the array.
      #   [ 1, 2, 3 ].__intersect__(4)
      #
      # @param [ Object ] object The object to intersect.
      #
      # @return [ Array ] The result of the intersect.
      #
      # @since 1.0.0
      def __intersect__(object)
        object.__intersect_from_object__(self)
      end

      # Merge this object into the provided array.
      #
      # @example Merge the object into the array.
      #   4.__intersect_from_array__([ 1, 2 ])
      #
      # @param [ Array ] value The array to intersect to.
      #
      # @return [ Array ] The merged object.
      #
      # @since 1.0.0
      def __intersect_from_array__(array)
        array & Array(self)
      end

      # Merge this object into the provided array.
      #
      # @example Merge the object into the array.
      #   4.__intersect_from_object__([ 1, 2 ])
      #
      # @param [ Object ] value The value to intersect to.
      #
      # @return [ Array ] The merged object.
      #
      # @since 1.0.0
      def __intersect_from_object__(object)
        Array(object) & Array(self)
      end

      # Combine the two objects using the union strategy.
      #
      # @example Add the object to the array.
      #   [ 1, 2, 3 ].__union__(4)
      #
      # @param [ Object ] object The object to union.
      #
      # @return [ Array ] The result of the union.
      #
      # @since 1.0.0
      def __union__(object)
        object.__union_from_object__(self)
      end

      # Merge this object into the provided array.
      #
      # @example Merge the object into the array.
      #   4.__union_from_object__([ 1, 2 ])
      #
      # @param [ Object ] value The value to union to.
      #
      # @return [ Array ] The merged object.
      #
      # @since 1.0.0
      def __union_from_object__(object)
        (Array(object) + Array(self)).uniq
      end

      # Deep copy the object. This is for API compatibility, but needs to be
      # overridden.
      #
      # @example Deep copy the object.
      #   1.__deep_copy__
      #
      # @return [ Object ] self.
      #
      # @since 1.0.0
      def __deep_copy__; self; end

      # Get the object as an array.
      #
      # @example Get the object as an array.
      #   4.__array__
      #
      # @return [ Array ] The wrapped object.
      #
      # @since 1.0.0
      def __array__
        [ self ]
      end

      # Get the object as expanded.
      #
      # @example Get the object expanded.
      #   obj.__expand_complex__
      #
      # @return [ Object ] self.
      #
      # @since 1.0.5
      def __expand_complex__
        self
      end

      # Is the object a regex.
      #
      # @example Is the object a regex?
      #   obj.regexp?
      #
      # @return [ false ] Always false.
      #
      # @since 1.0.4
      def regexp?
        false
      end

      module ClassMethods

        # Evolve the object.
        #
        # @note This is here for API compatibility.
        #
        # @example Evolve an object.
        #   Object.evolve("test")
        #
        # @return [ Object ] The provided object.
        #
        # @since 1.0.0
        def evolve(object)
          object
        end

        private

        # Evolve the object.
        #
        # @api private
        #
        # @todo Durran refactor out case statement.
        #
        # @example Evolve an object and yield.
        #   Object.evolve("test") do |obj|
        #     obj.to_s
        #   end
        #
        # @return [ Object ] The evolved object.
        #
        # @since 1.0.0
        def __evolve__(object)
          return nil if object.nil?
          case object
          when ::Array
            object.map{ |obj| evolve(obj) }
          when ::Range
            { "$gte" => evolve(object.min), "$lte" => evolve(object.max) }
          else
            yield(object)
          end
        end
      end
    end
  end
end

::Object.__send__(:include, Origin::Extensions::Object)
::Object.__send__(:extend, Origin::Extensions::Object::ClassMethods)
