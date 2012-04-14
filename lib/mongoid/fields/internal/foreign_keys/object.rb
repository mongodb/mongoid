# encoding: utf-8
module Mongoid
  module Fields
    module Internal
      module ForeignKeys

        # Defines the behaviour for integer foreign key fields.
        class Object
          include Serializable

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
            return nil if object.blank?
            if object_id_field?
              constraint.convert(object)
            else
              case object
              when ::Array
                object.replace(object.map { |arg| serialize(arg) })
              when ::Hash
                object.each_pair do |key, value|
                  object[key] = serialize(value)
                end
              else
                metadata.klass.fields["_id"].serialize(object)
              end
            end
          end

          # Evolve the object into the MongoDB friendly value used for querying it
          #
          # @example Evolve the object
          #   field.evolve(object)
          #
          # @param [ Object ] The object to evolve.
          #
          # @return [ Object ] The evolved object.
          #
          # @since 3.0.0
          def evolve(object)
            object.is_a?(Document) ? object.id : serialize(object)
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
  end
end
