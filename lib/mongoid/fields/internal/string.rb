# encoding: utf-8
module Mongoid #:nodoc:
  module Fields #:nodoc:
    module Internal #:nodoc:

      # Defines the behaviour for string fields.
      class String
        include Serializable

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
          object.try(:to_s)
        end
      end
    end
  end
end
