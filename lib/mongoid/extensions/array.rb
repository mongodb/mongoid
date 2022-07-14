# frozen_string_literal: true

module Mongoid
  module Extensions
    module Array

      # Evolve the array into an array of object ids.
      #
      # @example Evolve the array to object ids.
      #   [ id ].__evolve_object_id__
      #
      # @return [ Array<BSON::ObjectId> ] The converted array.
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
      def __find_args__
        flat_map{ |a| a.__find_args__ }.uniq{ |a| a.to_s }
      end

      # Mongoize the array into an array of object ids.
      #
      # @example Evolve the array to object ids.
      #   [ id ].__mongoize_object_id__
      #
      # @return [ Array<BSON::ObjectId> ] The converted array.
      def __mongoize_object_id__
        map!(&:__mongoize_object_id__).compact!
        self
      end

      # Converts the array for storing as a time.
      #
      # @note Returns a local time in the default time zone.
      #
      # @example Convert the array to a time.
      #   [ 2010, 1, 1 ].__mongoize_time__
      #   # => 2010-01-01 00:00:00 -0500
      #
      # @return [ Time | ActiveSupport::TimeWithZone ] Local time in the
      #   configured default time zone corresponding to date/time components
      #   in this array.
      def __mongoize_time__
        ::Time.configured.local(*self)
      end

      # Checks whether conditions given in this array are known to be
      # unsatisfiable, i.e., querying with this array will always return no
      # documents.
      #
      # This method used to assume that the array is the list of criteria
      # to be used with an $and operator. This assumption is no longer made;
      # therefore, since the interpretation of conditions in the array differs
      # between $and, $or and $nor operators, this method now always returns
      # false.
      #
      # This method is deprecated. Mongoid now uses
      # +_mongoid_unsatisfiable_criteria?+ internally; this method is retained
      # for backwards compatibility only. It always returns false.
      #
      # @return [ false ] Always false.
      # @deprecated
      def blank_criteria?
        false
      end

      # Is the array a set of multiple arguments in a method?
      #
      # @example Is this multi args?
      #   [ 1, 2, 3 ].multi_arged?
      #
      # @return [ true | false ] If the array is multi args.
      def multi_arged?
        !first.is_a?(Hash) && first.resizable? || size > 1
      end

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   object.mongoize
      #
      # @return [ Array | nil ] The object or nil.
      def mongoize
        ::Array.mongoize(self)
      end

      # Delete the first object in the array that is equal to the supplied
      # object and return it. This is much faster than performing a standard
      # delete for large arrays since it does not perform multiple deletes.
      #
      # @example Delete the first object.
      #   [ "1", "2", "1" ].delete_one("1")
      #
      # @param [ Object ] object The object to delete.
      #
      # @return [ Object ] The deleted object.
      def delete_one(object)
        position = index(object)
        position ? delete_at(position) : nil
      end

      # Returns whether the object's size can be changed.
      #
      # @example Is the object resizable?
      #   object.resizable?
      #
      # @return [ true ] true.
      def resizable?
        true
      end

      module ClassMethods

        # Convert the provided object to a proper array of foreign keys.
        #
        # @example Mongoize the object.
        #   Array.__mongoize_fk__(constraint, object)
        #
        # @param [ Association ] association The association metadata.
        # @param [ Object ] object The object to convert.
        #
        # @return [ Array ] The array of ids.
        def __mongoize_fk__(association, object)
          if object.resizable?
            object.blank? ? object : association.convert_to_foreign_key(object)
          else
            object.blank? ? [] : association.convert_to_foreign_key(Array(object))
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
        # @return [ Array | nil ] The object mongoized or nil.
        def mongoize(object)
          return if object.nil?
          case object
          when ::Array, ::Set
            object.map(&:mongoize)
          end
        end

        # Returns whether the object's size can be changed.
        #
        # @example Is the object resizable?
        #   Array.resizable?
        #
        # @return [ true ] true.
        def resizable?
          true
        end
      end
    end
  end
end

::Array.__send__(:include, Mongoid::Extensions::Array)
::Array.extend(Mongoid::Extensions::Array::ClassMethods)

::Mongoid.deprecate(Array, :blank_criteria)
