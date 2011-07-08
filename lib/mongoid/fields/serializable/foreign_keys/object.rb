# encoding: utf-8
module Mongoid #:nodoc:
  module Fields #:nodoc:
    module Serializable #:nodoc:
      module ForeignKeys #:nodoc:

        # Defines the behaviour for integer foreign key fields.
        class Object
          include Serializable

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
            object.blank? ? nil : constraint.convert(object)
          end

          protected

          # Get the constraint from the metadata once.
          #
          # @example Get the constraint.
          #   field.constraint
          #
          # @return [ Constraint ] The relation's contraint.
          #
          # @since 2.1.0
          def constraint
            @constraint ||= options[:metadata].constraint
          end
        end
      end
    end
  end
end
