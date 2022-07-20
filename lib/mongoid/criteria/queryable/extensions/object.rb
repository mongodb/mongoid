# frozen_string_literal: true

module Mongoid
  class Criteria
    module Queryable
      module Extensions

        # This module contains additional object behavior.
        module Object

          # Combine the two objects using the add strategy.
          #
          # @example Add the object to the array.
          #   [ 1, 2, 3 ].__add__(4)
          #
          # @param [ Object ] object The object to add.
          #
          # @return [ Object ] The result of the add.
          def __add__(object)
            (object == self) ? self : [ self, object ].flatten.uniq
          end

          # Merge this object into the provided array.
          #
          # @example Merge the object into the array.
          #   4.__add_from_array__([ 1, 2 ])
          #
          # @param [ Array ] array The array to add to.
          #
          # @return [ Array ] The merged object.
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
          def __intersect__(object)
            object.__intersect_from_object__(self)
          end

          # Merge this object into the provided array.
          #
          # @example Merge the object into the array.
          #   4.__intersect_from_array__([ 1, 2 ])
          #
          # @param [ Array ] array The array to intersect to.
          #
          # @return [ Array ] The merged object.
          def __intersect_from_array__(array)
            array & Array(self)
          end

          # Merge this object into the provided array.
          #
          # @example Merge the object into the array.
          #   4.__intersect_from_object__([ 1, 2 ])
          #
          # @param [ Object ] object The value to intersect to.
          #
          # @return [ Array ] The merged object.
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
          def __union__(object)
            object.__union_from_object__(self)
          end

          # Merge this object into the provided array.
          #
          # @example Merge the object into the array.
          #   4.__union_from_object__([ 1, 2 ])
          #
          # @param [ Object ] object The value to union to.
          #
          # @return [ Array ] The merged object.
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
          def __deep_copy__; self; end

          # Get the object as an array.
          #
          # @example Get the object as an array.
          #   4.__array__
          #
          # @return [ Array ] The wrapped object.
          def __array__
            [ self ]
          end

          # Get the object as expanded.
          #
          # @example Get the object expanded.
          #   obj.__expand_complex__
          #
          # @return [ Object ] self.
          def __expand_complex__
            self
          end

          # Is the object a regex.
          #
          # @example Is the object a regex?
          #   obj.regexp?
          #
          # @return [ false ] Always false.
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
            def __evolve__(object)
              return nil if object.nil?
              case object
              when ::Array
                object.map{ |obj| evolve(obj) }
              when ::Range
                object.__evolve_range__
              else
                res = yield(object)
                res.nil? ? object : res
              end
            end
          end
        end
      end
    end
  end
end

::Object.__send__(:include, Mongoid::Criteria::Queryable::Extensions::Object)
::Object.__send__(:extend, Mongoid::Criteria::Queryable::Extensions::Object::ClassMethods)
