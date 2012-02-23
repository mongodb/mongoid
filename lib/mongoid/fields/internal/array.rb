# encoding: utf-8
module Mongoid #:nodoc:
  module Fields #:nodoc:
    module Internal #:nodoc:

      # Defines the behaviour for array fields.
      class Array
        include Serializable

        # Adds the atomic changes for this type of resizable field.
        #
        # @example Add the atomic changes.
        #   field.add_atomic_changes(doc, "key", {}, [], [])
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
          mods[key] = new
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
          return object unless object
          ::Array.wrap(object)
        end
      end
    end
  end
end
