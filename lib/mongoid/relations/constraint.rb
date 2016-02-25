# encoding: utf-8
module Mongoid
  module Relations

    # Used for converting foreign key values to the correct type based on the
    # types of ids that the document stores.
    #
    # @note Durran: The name of this class is this way to match the metadata
    #   getter, and foreign_key was already taken there.
    class Constraint
      attr_reader :metadata

      # Create the new constraint with the metadata.
      #
      # @example Instantiate the constraint.
      #   Constraint.new(metdata)
      #
      # @param [ Metadata ] metadata The metadata of the relation.
      #
      # @since 2.0.0.rc.7
      def initialize(metadata)
        @metadata = metadata
      end

      # Convert the supplied object to the appropriate type to set as the
      # foreign key for a relation.
      #
      # @example Convert the object.
      #   constraint.convert("12345")
      #
      # @param [ Object ] object The object to convert.
      #
      # @return [ Object ] The object cast to the correct type.
      #
      # @since 2.0.0.rc.7
      def convert(object)
        return convert_polymorphic(object) if metadata.polymorphic?
        klass, field = metadata.klass, metadata.klass.fields["_id"]
        if klass.using_object_ids?
          BSON::ObjectId.mongoize(object)
        elsif object.is_a?(::Array)
          object.map!{ |obj| field.mongoize(obj) }
        else
          field.mongoize(object)
        end
      end

      private
      
      def convert_polymorphic(object)
        object.respond_to?(:id) ? object.id : object
      end
    end
  end
end
