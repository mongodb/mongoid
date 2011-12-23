# encoding: utf-8
module Mongoid #:nodoc:
  module Fields #:nodoc:
    module Internal #:nodoc:

      # Defines the behaviour for symbol fields.
      class Symbol
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
        # @return [ Symbol ] The converted symbol.
        #
        # @since 2.1.0
        def serialize(object)
          object.blank? ? nil : object.to_sym
        end
        alias :deserialize :serialize
      end
    end
  end
end
