# encoding: utf-8
module Mongoid
  module Fields
    module Internal
      module ForeignKeys

        # Defines the behaviour for array foreign key fields.
        class Array
          include Serializable

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

          # Array fields are resizable.
          #
          # @example Is this field resizable?
          #   field.resizable?
          #
          # @return [ true ] Always true.
          #
          # @since 2.4.0
          def resizable?; true; end

          # Serialize the object from the type defined in the model to a MongoDB
          # compatible object to store.
          #
          # @example Serialize the field.
          #   field.serialize(object)
          #
          # @param [ Object ] object The object to cast.
          #
          # @return [ Array ] The converted object.
          #
          # @since 2.1.0
          def serialize(object)
            object ? constraint.convert(object) : []
          end
          alias :evolve :serialize

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
  end
end
