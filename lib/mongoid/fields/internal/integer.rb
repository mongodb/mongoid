# encoding: utf-8
module Mongoid #:nodoc:
  module Fields #:nodoc:
    module Internal #:nodoc:

      # Defines the behaviour for integer fields.
      class Integer
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
        # @return [ Integer ] The converted integer.
        #
        # @since 2.1.0
        def serialize(object)
          return nil if object.blank?
          numeric(object) rescue object
        end

        private

        # Get the numeric value for the provided object.
        #
        # @example Get the numeric value.
        #   field.numeric("1120")
        #
        # @param [ Object ] object The object to convert.
        #
        # @return [ Integer, Float ] The number.
        #
        # @since 2.3.0
        def numeric(object)
          object.to_s =~ /(^[-+]?[0-9]+$)|(\.0+)$/ ? object.to_i : Float(object)
        end
      end
    end
  end
end
