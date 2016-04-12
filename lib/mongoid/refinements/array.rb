module Mongoid
  module Refinements

    refine Array do

      # Get the array of args as arguments for a find query.
      #
      # @example Get the array as find args.
      #   [ 1, 2, 3 ].as_find_arguments
      #
      # @return [ Array ] The array of args.
      #
      # @since 6.0.0
      def as_find_arguments
        flat_map{ |a| a.as_find_arguments }.uniq{ |a| a.to_s }
      end

      # Check if the array is part of a blank relation criteria.
      #
      # @example Is the array blank criteria?
      #   [].blank_criteria?
      #
      # @return [ true, false ] If the array is blank criteria.
      #
      # @since 6.0.0
      def blank_criteria?
        any?{ |a| a.blank_criteria? }
      end

      # Delete the first object in the array that is equal to the supplied
      # object and return it. This is much faster than performing a standard
      # delete for large arrays ince it attempt to delete multiple in the
      # other.
      #
      # @example Delete the first object.
      #   [ "1", "2", "1" ].delete_one("1")
      #
      # @param [ Object ] object The object to delete.
      #
      # @return [ Object ] The deleted object.
      #
      # @since 2.1.0
      def delete_one(object)
        position = index(object)
        position ? delete_at(position) : nil
      end

      # Evolve the array into an array of object ids.
      #
      # @example Evolve the array to object ids.
      #   [ id ].evolve_object_id
      #
      # @return [ Array<BSON::ObjectId> ] The converted array.
      #
      # @since 6.0.0
      def evolve_object_id
        map!{ |o| o.evolve_object_id }; self
      end

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   object.mongoize
      #
      # @return [ Array ] The object.
      #
      # @since 6.0.0
      def mongoize
        ::Array.mongoize(self)
      end

      # Mongoize the array into an array of object ids.
      #
      # @example Evolve the array to object ids.
      #   [ id ].mongoize_object_id
      #
      # @return [ Array<BSON::ObjectId> ] The converted array.
      #
      # @since 6.0.0
      def mongoize_object_id
        map!{ |o| o.mongoize_object_id }.compact!; self
      end

      # Converts the array for storing as a time.
      #
      # @example Convert the array to a time.
      #   [ 2010, 1, 1 ].mongoize_time
      #
      # @return [ Time ] The time.
      #
      # @since 6.0.0
      def mongoize_time
        ::Time.configured.local(*self)
      end

      # Is the array a set of multiple arguments in a method?
      #
      # @example Is this multi args?
      #   [ 1, 2, 3 ].multi_arged?
      #
      # @return [ true, false ] If the array is multi args.
      #
      # @since 6.0.0
      def multi_arged?
        !first.is_a?(Hash) && first.resizable? || size > 1
      end

      # Is the object's size changable?
      #
      # @example Is the object resizable?
      #   [].resizable?
      #
      # @return [ true ] true.
      #
      # @since 6.0.0
      def resizable?; true; end

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
        object.__add_from_array__(self)
      end

      # Return the object as an array.
      #
      # @example Get the array.
      #   [ 1, 2 ].__array__
      #
      # @return [ Array ] self
      #
      # @since 1.0.0
      def __array__; self; end

      # Makes a deep copy of the array, deep copying every element inside the
      # array.
      #
      # @example Get a deep copy of the array.
      #   [ 1, 2, 3 ].__deep_copy__
      #
      # @return [ Array ] The deep copy of the array.
      #
      # @since 1.0.0
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
      #
      # @since 1.0.0
      def __evolve_date__
        map { |value| value.__evolve_date__ }
      end

      # Get the object as expanded.
      #
      # @example Get the object expanded.
      #   obj.__expand_complex__
      #
      # @return [ Array ] The expanded array.
      #
      # @since 1.1.0
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
      #
      # @since 1.0.0
      def __evolve_time__
        map { |value| value.__evolve_time__ }
      end

      # Combine the two objects using an intersection strategy.
      #
      # @example Interset with the object.
      #   [ 1, 2 ].__intersect__(3)
      #
      # @param [ Object ] object The object to intersect with.
      #
      # @return [ Object ] The result of the intersection.
      #
      # @since 1.0.0
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
      #
      # @since 1.0.0
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
      #
      # @since 1.0.0
      def __sort_pair__
        { first => last.to_direction }
      end

      # Update all the values in the hash with the provided block.
      #
      # @example Update the values in place.
      #   [ 1, 2, 3 ].update_values(&:to_s)
      #
      # @param [ Proc ] block The block to execute on each value.
      #
      # @return [ Array ] the array.
      #
      # @since 1.0.0
      def update_values(&block)
        replace(map(&block))
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
      #
      # @since 1.0.0
      def multi
        first.is_a?(::Symbol) || first.is_a?(::String) ? [ self ] : self
      end
    end

    refine Array.singleton_class do

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   Array.mongoize([ 1, 2, 3 ])
      #
      # @param [ Object ] object The object to mongoize.
      #
      # @return [ Array ] The object mongoized.
      #
      # @since 6.0.0
      def mongoize(object)
        if object.is_a?(::Array)
          evolve(object).collect{ |obj| obj.class.mongoize(obj) }
        else
          evolve(object)
        end
      end

      # Convert the provided object to a propery array of foreign keys.
      #
      # @example Mongoize the object.
      #   Array.mongoize_fk(constraint, object)
      #
      # @param [ Constraint ] constraint The metadata constraint.
      # @param [ Object ] object The object to convert.
      #
      # @return [ Array ] The array of ids.
      #
      # @since 6.0.0
      def mongoize_fk(constraint, object)
        if object.resizable?
          object.blank? ? object : constraint.convert(object)
        else
          object.blank? ? [] : constraint.convert(Array(object))
        end
      end

      # Is the object's size changable?
      #
      # @example Is the object resizable?
      #   Array.resizable?
      #
      # @return [ true ] true.
      #
      # @since 6.0.0
      def resizable?; true; end

      # Evolve the object when the serializer is defined as an array.
      #
      # @example Evolve the object.
      #   Array.evolve(1)
      #
      # @param [ Object ] The object to evolve.
      #
      # @return [ Object ] The evolved object.
      #
      # @since 1.0.0
      def evolve(object)
        if object.is_a?(::Array)
          object.map { |obj| obj.class.evolve(obj) }
        else
          object
        end
      end
    end
  end
end
