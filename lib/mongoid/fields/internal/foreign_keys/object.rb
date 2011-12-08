# encoding: utf-8
module Mongoid #:nodoc:
  module Fields #:nodoc:
    module Internal #:nodoc:
      module ForeignKeys #:nodoc:

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
        end
      end
    end
  end
end
