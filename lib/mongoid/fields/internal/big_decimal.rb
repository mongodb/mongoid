# encoding: utf-8
module Mongoid #:nodoc:
  module Fields #:nodoc:
    module Internal #:nodoc:

      # Defines the behaviour for big decimal fields.
      class BigDecimal
        include Serializable

        # Deserialize this field from the type stored in MongoDB to the type
        # defined on the model.
        #
        # @example Deserialize the field.
        #   field.deserialize(object)
        #
        # @param [ Object ] object The object to cast.
        #
        # @return [ BigDecimal ] The converted big decimal.
        #
        # @since 2.1.0
        def deserialize(object)
          return object unless object
          begin
            Float(object)
            ::BigDecimal.new(object)
          rescue ArgumentError, TypeError
            object
          end
        end

        # Special case to serialize the object.
        #
        # @example Convert to a selection.
        #   field.selection(object)
        #
        # @param [ Object ] The object to convert.
        #
        # @return [ Object ] The converted object.
        #
        # @since 2.4.0
        def selection(object)
          return object if object.is_a?(::Hash)
          serialize(object)
        end

        # Serialize the object from the type defined in the model to a MongoDB
        # compatible object to store.
        #
        # @example Serialize the field.
        #   field.serialize(object)
        #
        # @param [ Object ] object The object to cast.
        #
        # @return [ String ] The converted string.
        #
        # @since 2.1.0
        def serialize(object)
          object ? object.to_s : object
        end
      end
    end
  end
end
