# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Array #:nodoc:

      # Make a deep copy of the array.
      #
      # @example Make a deep copy.
      #   [ 1, 2, 3 ].deep_dup
      #
      # @return [ Array ] The deep copy.
      #
      # @since 2.4.0
      def deep_dup
        [].tap do |copy|
          each do |value|
            copy.push(value.deep_dup)
          end
        end
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
    end
  end
end

::Array.__send__(:include, Mongoid::Extensions::Array)
