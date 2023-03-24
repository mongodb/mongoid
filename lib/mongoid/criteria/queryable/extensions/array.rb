# frozen_string_literal: true

module Mongoid
  class Criteria
    module Queryable
      module Extensions

        # The array module adds custom behavior for Origin onto the Array class.
        module Array

          # Combine the two objects using the add strategy.
          #
          # @example Add the object to the array.
          #   [ 1, 2, 3 ].__add__(4)
          #
          # @param [ Object ] object The object to add.
          #
          # @return [ Object ] The result of the add.
          def __add__(object)
            object.__add_from_array__(self)
          end

          # Return the object as an array.
          #
          # @example Get the array.
          #   [ 1, 2 ].__array__
          #
          # @return [ Array ] self
          def __array__; self; end

          # Makes a deep copy of the array, deep copying every element inside the
          # array.
          #
          # @example Get a deep copy of the array.
          #   [ 1, 2, 3 ].__deep_copy__
          #
          # @return [ Array ] The deep copy of the array.
          def __deep_copy__
            map { |value| value.__deep_copy__ }
          end

          # Evolve the array into an array of mongo friendly dates. (Times at
          # midnight).
          #
          # @example Evolve the array to dates.
          #   [ Date.new(2010, 1, 1) ].__evolve_date__
          #
          # @return [ Array<Time> ] The array as times at midnight UTC.
          def __evolve_date__
            map { |value| value.__evolve_date__ }
          end

          # Get the object as expanded.
          #
          # @example Get the object expanded.
          #   obj.__expand_complex__
          #
          # @return [ Array ] The expanded array.
          def __expand_complex__
            map do |value|
              value.__expand_complex__
            end
          end

          # Evolve the array to an array of times.
          #
          # @example Evolve the array to times.
          #   [ 1231231231 ].__evolve_time__
          #
          # @return [ Array<Time> ] The array as times.
          def __evolve_time__
            map { |value| value.__evolve_time__ }
          end

          # Combine the two objects using an intersection strategy.
          #
          # @example Intersect with the object.
          #   [ 1, 2 ].__intersect__(3)
          #
          # @param [ Object ] object The object to intersect with.
          #
          # @return [ Object ] The result of the intersection.
          def __intersect__(object)
            object.__intersect_from_array__(self)
          end

          # Gets the array as options in the proper format to pass as MongoDB sort
          # criteria.
          #
          # @example Get the array as sorting options.
          #   [ :field, 1 ].__sort_option__
          #
          # @return [ Hash ] The array as sort criterion.
          def __sort_option__
            multi.inject({}) do |options, criteria|
              options.merge!(criteria.__sort_pair__)
              options
            end
          end

          # Get the array as a sort pair.
          #
          # @example Get the array as field/direction pair.
          #   [ field, 1 ].__sort_pair__
          #
          # @return [ Hash ] The field/direction pair.
          def __sort_pair__
            { first => Mongoid::Criteria::Translator.to_direction(last) }
          end

          private

          # Converts the array to a multi-dimensional array.
          #
          # @api private
          #
          # @example Convert to multi-dimensional.
          #   [ 1, 2, 3 ].multi
          #
          # @return [ Array ] The multi-dimensional array.
          def multi
            first.is_a?(::Symbol) || first.is_a?(::String) ? [ self ] : self
          end

          module ClassMethods

            # Evolve the object when the serializer is defined as an array.
            #
            # @example Evolve the object.
            #   Array.evolve(1)
            #
            # @param [ Object ] object The object to evolve.
            #
            # @return [ Object ] The evolved object.
            def evolve(object)
              case object
              when ::Array, ::Set
                object.map { |obj| obj.class.evolve(obj) }
              else
                object
              end
            end
          end
        end
      end
    end
  end
end

::Array.__send__(:include, Mongoid::Criteria::Queryable::Extensions::Array)
::Array.__send__(:extend, Mongoid::Criteria::Queryable::Extensions::Array::ClassMethods)
