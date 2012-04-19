# encoding: utf-8
module Mongoid
  module Fields
    class ForeignKey < Standard

      # Is this field a foreign key?
      #
      # @example Is the field a foreign key?
      #   field.foreign_key?
      #
      # @return [ true, false ] If the field is a foreign key.
      #
      # @since 2.4.0
      def foreign_key?
        true
      end

      def mongoize(object)
        type.__mongoize_fk__(constraint, object, object_id_field?)
      end

      # Is the field a BSON::ObjectId?
      #
      # @example Is the field a BSON::ObjectId?
      #   field.object_id_field?
      #
      # @return [ true, false ] If the field is a BSON::ObjectId.
      #
      # @since 2.2.0
      def object_id_field?
        @object_id_field ||=
          metadata.polymorphic? ? true : metadata.klass.using_object_ids?
      end

      private

      # Evaluate the default proc. In some cases we need to instance exec,
      # in others we don't.
      #
      # @example Eval the default proc.
      #   field.evaluate_default_proc(band)
      #
      # @param [ Document ] doc The document.
      #
      # @return [ Object ] The called proc.
      #
      # @since 3.0.0
      def evaluate_default_proc(doc)
        serialize_default(default_val[])
      end

      # This is used when default values need to be serialized. Most of the
      # time just return the object.
      #
      # @api private
      #
      # @example Serialize the default value.
      #   field.serialize_default(obj)
      #
      # @param [ Object ] object The default.
      #
      # @return [ Object ] The serialized default.
      #
      # @since 3.0.0
      def serialize_default(object); object; end
    end
  end
end
