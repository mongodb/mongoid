# encoding: utf-8
module Mongoid #:nodoc:
  module Fields #:nodoc:
    module Internal #:nodoc:
      module ForeignKeys #:nodoc:

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
          def add_atomic_changes(document, name, key, mods, new, old)
            pushes = (new || []) - (old || [])
            pulls = (old || []) - (new || [])
            if old.nil?
              mods[key] = pushes
            elsif !pushes.empty? && !pulls.empty?
              mods[key] = document.attributes[name]
            elsif !pushes.empty?
              document.atomic_array_add_to_sets[key] = pushes
            elsif !pulls.empty?
              document.atomic_array_pulls[key] = pulls
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
        end
      end
    end
  end
end
