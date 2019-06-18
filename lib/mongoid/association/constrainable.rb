# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Association

    # Used for converting foreign key values to the correct type based on the
    # types of ids that the document stores.
    #
    module Constrainable

      # Convert the supplied object to the appropriate type to set as the
      # foreign key for an association.
      #
      # @example Convert the object.
      #   constraint.convert("12345")
      #
      # @param [ Object ] object The object to convert.
      #
      # @return [ Object ] The object cast to the correct type.
      #
      # @since 2.0.0.rc.7
      def convert_to_foreign_key(object)
        return convert_polymorphic(object) if polymorphic?
        field = relation_class.fields["_id"]
        if relation_class.using_object_ids?
          BSON::ObjectId.mongoize(object)
        elsif object.is_a?(::Array)
          object.map!{ |obj| field.mongoize(obj) }
        else
          field.mongoize(object)
        end
      end

      private

      def convert_polymorphic(object)
        if object.is_a?(Mongoid::Document)
          object.id
        else
          BSON::ObjectId.mongoize(object)
        end
      end
    end
  end
end
