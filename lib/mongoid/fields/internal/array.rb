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
        # @param [ String ] key The name of the field.
        # @param [ Hash ] mods The current modifications.
        # @param [ Array ] new The new elements to add.
        # @param [ Array ] old The old elements getting removed.
        #
        # @since 2.4.0
        def add_atomic_changes(document, key, mods, new, old)
          if new.any? && old.any?
            mods[key] = document.attributes[key]
          elsif new.any?
            document.atomic_array_pushes[key] = new
          elsif old.any?
            document.atomic_array_pulls[key] = old
          end
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
          raise_or_return(object)
        end

        protected

        # If the value is not an array or nil we will raise an error,
        # otherwise return the value.
        #
        # @example Raise or return the value.
        #   field.raise_or_return([])
        #
        # @param [ Object ] value The value to check.a
        #
        # @raise [ InvalidType ] If not passed an array.
        #
        # @return [ Array ] The array.
        #
        # @since 2.1.0
        def raise_or_return(value)
          unless value.nil? || value.is_a?(::Array)
            raise Mongoid::Errors::InvalidType.new(::Array, value)
          end
          value
        end
      end
    end
  end
end
