# encoding: utf-8
module Mongoid #:nodoc:
  module Fields #:nodoc:
    module Serializable #:nodoc:
      module ForeignKeys #:nodoc:

        # Defines the behaviour for array fields.
        class Array
          include Serializable

          # Get the default value for the field. If the default is a proc call
          # it, otherwise clone the array.
          #
          # @example Get the default.
          #   field.default
          #
          # @return [ Object ] The default value cloned.
          #
          # @since 2.1.0
          def default
            default_value.dup
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
            object.blank? ? [] : constraint.convert(object)
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
