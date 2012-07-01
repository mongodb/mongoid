# encoding: utf-8
module Mongoid
  module Extensions
    module Array

      # Evolve the array into an array of object ids.
      #
      # @example Evolve the array to object ids.
      #   [ id ].__evolve_object_id__
      #
      # @return [ Array<Moped::BSON::ObjectId> ] The converted array.
      #
      # @since 3.0.0
      def __evolve_object_id__
        map!(&:__evolve_object_id__)
        self
      end

      # Get the array of args as arguments for a find query.
      #
      # @example Get the array as find args.
      #   [ 1, 2, 3 ].__find_args__
      #
      # @return [ Array ] The array of args.
      #
      # @since 3.0.0
      def __find_args__
        flat_map{ |a| a.__find_args__ }.uniq_by{ |a| a.to_s }
      end

      # Mongoize the array into an array of object ids.
      #
      # @example Evolve the array to object ids.
      #   [ id ].__mongoize_object_id__
      #
      # @return [ Array<Moped::BSON::ObjectId> ] The converted array.
      #
      # @since 3.0.0
      def __mongoize_object_id__
        map!(&:__mongoize_object_id__).compact!
        self
      end

      # Converts the array for storing as a time.
      #
      # @example Convert the array to a time.
      #   [ 2010, 1, 1 ].__mongoize_time__
      #
      # @return [ Time ] The time.
      #
      # @since 3.0.0
      def __mongoize_time__
        ::Time.configured.local(*self)
      end

      # Is the array a set of multiple arguments in a method?
      #
      # @example Is this multi args?
      #   [ 1, 2, 3 ].multi_arged?
      #
      # @return [ true, false ] If the array is multi args.
      #
      # @since 3.0.0
      def multi_arged?
        first.resizable? || size > 1
      end

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   object.mongoize
      #
      # @return [ Array ] The object.
      #
      # @since 3.0.0
      def mongoize
        ::Array.mongoize(self)
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

      # Is the object's size changable?
      #
      # @example Is the object resizable?
      #   object.resizable?
      #
      # @return [ true ] true.
      #
      # @since 3.0.0
      def resizable?
        true
      end

      module ClassMethods

        # Convert the provided object to a propery array of foreign keys.
        #
        # @example Mongoize the object.
        #   Array.__mongoize_fk__(constraint, object)
        #
        # @param [ Constraint ] constraint The metadata constraint.
        # @param [ Object ] object The object to convert.
        #
        # @return [ Array ] The array of ids.
        #
        # @since 3.0.0
        def __mongoize_fk__(constraint, object)
          if object.resizable?
            object.blank? ? object : constraint.convert(object)
          else
            object.blank? ? [] : constraint.convert(Array(object))
          end
        end

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
        # @since 3.0.0
        def mongoize(object)
          evolve(object)
        end

        # Is the object's size changable?
        #
        # @example Is the object resizable?
        #   Array.resizable?
        #
        # @return [ true ] true.
        #
        # @since 3.0.0
        def resizable?
          true
        end
      end
    end
  end
end

::Array.__send__(:include, Mongoid::Extensions::Array)
::Array.__send__(:extend, Mongoid::Extensions::Array::ClassMethods)
