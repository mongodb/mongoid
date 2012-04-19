# encoding: utf-8
module Mongoid
  module Extensions
    module Array

      def __evolve_object_id__
        map!(&:__evolve_object_id__).compact!
        self
      end

      def __mongoize_time__
        time = Mongoid::Config.use_activesupport_time_zone? ? (::Time.zone || ::Time) : ::Time
        time.local(*self)
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

      def resizable?
        true
      end

      module ClassMethods

        def __mongoize_fk__(constraint, object, using_object_ids)
          object ? constraint.convert(object) : []
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
      end
    end
  end
end

::Array.__send__(:include, Mongoid::Extensions::Array)
::Array.__send__(:extend, Mongoid::Extensions::Array::ClassMethods)
