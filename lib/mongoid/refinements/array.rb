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
    end
  end
end