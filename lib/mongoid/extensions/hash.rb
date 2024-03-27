# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module Extensions

    # Adds type-casting behavior to Hash class.
    module Hash

      # Evolves each value in the hash to an object id if it is convertable.
      #
      # @example Convert the hash values.
      #   { field: id }.__evolve_object_id__
      #
      # @return [ Hash ] The converted hash.
      def __evolve_object_id__
        transform_values!(&:__evolve_object_id__)
      end

      # Mongoizes each value in the hash to an object id if it is convertable.
      #
      # @example Convert the hash values.
      #   { field: id }.__mongoize_object_id__
      #
      # @return [ Hash ] The converted hash.
      def __mongoize_object_id__
        if id = self['$oid']
          BSON::ObjectId.from_string(id)
        else
          transform_values!(&:__mongoize_object_id__)
        end
      end

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   object.mongoize
      #
      # @return [ Hash | nil ] The object mongoized or nil.
      def mongoize
        ::Hash.mongoize(self)
      end

      # Can the size of this object change?
      #
      # @example Is the hash resizable?
      #   {}.resizable?
      #
      # @return [ true ] true.
      def resizable?
        true
      end

      private

      module ClassMethods

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   Hash.mongoize([ 1, 2, 3 ])
        #
        # @param [ Object ] object The object to mongoize.
        #
        # @return [ Hash | nil ] The object mongoized or nil.
        def mongoize(object)
          return if object.nil?
          case object
          when BSON::Document
            object.dup.transform_values!(&:mongoize)
          when Hash
            BSON::Document.new(object.transform_values(&:mongoize))
          end
        end

        # Can the size of this object change?
        #
        # @example Is the hash resizable?
        #   {}.resizable?
        #
        # @return [ true ] true.
        def resizable?
          true
        end
      end
    end
  end
end

::Hash.__send__(:include, Mongoid::Extensions::Hash)
::Hash.extend(Mongoid::Extensions::Hash::ClassMethods)
