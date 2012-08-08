# encoding: utf-8
module Mongoid
  module Fields
    class ForeignKey < Standard

      # Adds the atomic changes for this type of resizable field.
      #
      # @example Add the atomic changes.
      #   field.add_atomic_changes(doc, "key", {}, [], [])
      #
      # @todo: Durran: Refactor, big time.
      #
      # @param [ Document ] document The document to add to.
      # @param [ String ] name The name of the field.
      # @param [ String ] key The atomic location of the field.
      # @param [ Hash ] mods The current modifications.
      # @param [ Array ] new The new elements to add.
      # @param [ Array ] old The old elements getting removed.
      #
      # @since 2.4.0
      def add_atomic_changes(document, name, key, mods, new_elements, old_elements)
        old = (old_elements || [])
        new = (new_elements || [])
        if new.length > old.length
          if new.first(old.length) == old
            document.atomic_array_add_to_sets[key] = new.drop(old.length)
          else
            mods[key] = document.attributes[name]
          end
        elsif new.length < old.length
          pulls = old - new
          if new == old - pulls
            document.atomic_array_pulls[key] = pulls
          else
            mods[key] = document.attributes[name]
          end
        elsif new != old
          mods[key] = document.attributes[name]
        end
      end

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

      # Evolve the object into an id compatible object.
      #
      # @example Evolve the object.
      #   field.evolve(object)
      #
      # @param [ Object ] object The object to evolve.
      #
      # @return [ Object ] The evolved object.
      #
      # @since 3.0.0
      def evolve(object)
        if object_id_field? || object.is_a?(Document)
          object.__evolve_object_id__
        else
          related_id_field.evolve(object)
        end
      end

      # Does this field do lazy default evaluation?
      #
      # @example Is the field lazy?
      #   field.lazy?
      #
      # @return [ true, false ] If the field is lazy.
      #
      # @since 3.1.0
      def lazy?
        type.resizable?
      end

      # Mongoize the object into the Mongo friendly value.
      #
      # @example Mongoize the object.
      #   field.mongoize(object)
      #
      # @param [ Object ] object The object to Mongoize.
      #
      # @return [ Object ] The mongoized object.
      #
      # @since 3.0.0
      def mongoize(object)
        if type.resizable? || object_id_field?
          type.__mongoize_fk__(constraint, object)
        else
          related_id_field.mongoize(object)
        end
      end

      # Is the field a Moped::BSON::ObjectId?
      #
      # @example Is the field a Moped::BSON::ObjectId?
      #   field.object_id_field?
      #
      # @return [ true, false ] If the field is a Moped::BSON::ObjectId.
      #
      # @since 2.2.0
      def object_id_field?
        @object_id_field ||=
          metadata.polymorphic? ? true : metadata.klass.using_object_ids?
      end

      # Returns true if an array, false if not.
      #
      # @example Is the field resizable?
      #   field.resizable?
      #
      # @return [ true, false ] If the field is resizable.
      #
      # @since 3.0.2
      def resizable?
        type.resizable?
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

      # Get the id field of the relation.
      #
      # @api private
      #
      # @example Get the related id field.
      #   field.related_id_field
      #
      # @return [ Fields::Standard ] The field.
      #
      # @since 3.0.0
      def related_id_field
        @related_id_field ||= metadata.klass.fields["_id"]
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
