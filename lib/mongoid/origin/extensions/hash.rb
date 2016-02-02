# encoding: utf-8
module Origin
  module Extensions

    # This module contains additional hash behaviour.
    module Hash

      # Add an object to a hash using the merge strategies.
      #
      # @example Add an object to a hash.
      #   { field: value }.__add__({ field: other_value })
      #
      # @param [ Hash ] object The other hash to add.
      #
      # @return [ Hash ] The hash with object added.
      #
      # @since 1.0.0
      def __add__(object)
        apply_strategy(:__add__, object)
      end

      # Merge this hash into the provided array.
      #
      # @example Merge the hash into the array.
      #   { field: value }.__add_from_array__([ 1, 2 ])
      #
      # @param [ Array ] value The array to add to.
      #
      # @return [ Hash ] The merged hash.
      #
      # @since 1.0.0
      def __add_from_array__(array)
        { keys.first => array.__add__(values.first) }
      end

      # Add an object to a hash using the merge strategies.
      #
      # @example Add an object to a hash.
      #   { field: value }.__intersect__({ field: other_value })
      #
      # @param [ Hash ] object The other hash to intersect.
      #
      # @return [ Hash ] The hash with object intersected.
      #
      # @since 1.0.0
      def __intersect__(object)
        apply_strategy(:__intersect__, object)
      end

      # Merge this hash into the provided array.
      #
      # @example Merge the hash into the array.
      #   { field: value }.__intersect_from_array__([ 1, 2 ])
      #
      # @param [ Array ] value The array to intersect to.
      #
      # @return [ Hash ] The merged hash.
      #
      # @since 1.0.0
      def __intersect_from_array__(array)
        { keys.first => array.__intersect__(values.first) }
      end

      # Merge this hash into the provided object.
      #
      # @example Merge the hash into the object.
      #   { field: value }.__intersect_from_object__([ 1, 2 ])
      #
      # @param [ Object ] value The object to intersect to.
      #
      # @return [ Hash ] The merged hash.
      #
      # @since 1.0.0
      def __intersect_from_object__(object)
        { keys.first => object.__intersect__(values.first) }
      end

      # Add an object to a hash using the merge strategies.
      #
      # @example Add an object to a hash.
      #   { field: value }.__union__({ field: other_value })
      #
      # @param [ Hash ] object The other hash to union.
      #
      # @return [ Hash ] The hash with object unioned.
      #
      # @since 1.0.0
      def __union__(object)
        apply_strategy(:__union__, object)
      end

      # Merge this hash into the provided object.
      #
      # @example Merge the hash into the object.
      #   { field: value }.__union_from_object__([ 1, 2 ])
      #
      # @param [ Object ] value The object to union to.
      #
      # @return [ Hash ] The merged hash.
      #
      # @since 1.0.0
      def __union_from_object__(object)
        { keys.first => object.__union__(values.first) }
      end

      # Make a deep copy of this hash.
      #
      # @example Make a deep copy of the hash.
      #   { field: value }.__deep_copy__
      #
      # @return [ Hash ] The copied hash.
      #
      # @since 1.0.0
      def __deep_copy__
        {}.tap do |copy|
          each_pair do |key, value|
            copy.store(key, value.__deep_copy__)
          end
        end
      end

      # Get the hash as a sort option.
      #
      # @example Get the hash as a sort option.
      #   { field: 1 }.__sort_option__
      #
      # @return [ Hash ] The hash as sort option.
      #
      # @since 1.0.0
      def __sort_option__
        tap do |hash|
          hash.each_pair do |key, value|
            hash.store(key, value.to_direction)
          end
        end
      end

      # Get the object as expanded.
      #
      # @example Get the object expanded.
      #   obj.__expand_complex__
      #
      # @return [ Hash ] The expanded hash.
      #
      # @since 1.0.5
      def __expand_complex__
        replacement = {}
        each_pair do |key, value|
          replacement.merge!(key.__expr_part__(value.__expand_complex__))
        end
        replacement
      end

      # Update all the values in the hash with the provided block.
      #
      # @example Update the values in place.
      #   { field: "1" }.update_values(&:to_i)
      #
      # @param [ Proc ] block The block to execute on each value.
      #
      # @return [ Hash ] the hash.
      #
      # @since 1.0.0
      def update_values(&block)
        each_pair do |key, value|
          store(key, block[value])
        end
      end

      private

      # Apply the provided strategy for the hash with the given object.
      #
      # @api private
      #
      # @example Apply the strategy.
      #   { field: value }.apply_strategy(:__add__, 1)
      #
      # @param [ Symbol ] strategy The strategy to apply.
      # @param [ Object ] object The object to merge.
      #
      # @return [ Hash ] The merged hash.
      #
      # @since 1.0.0
      def apply_strategy(strategy, object)
        tap do |hash|
          object.each_pair do |key, value|
            hash.store(key, hash[key].send(strategy, value))
          end
        end
      end
    end
  end
end

::Hash.__send__(:include, Origin::Extensions::Hash)
