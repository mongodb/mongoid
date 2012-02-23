# encoding: utf-8
module Mongoid #:nodoc:
  module Fields #:nodoc:
    module Internal #:nodoc:
      # Defines the behaviour for hash fields.
      class Hash
        include Serializable

        # Serialize the object from the type defined in the model to a MongoDB
        # compatible object to store.
        #
        # @example Serialize the field.
        #   field.serialize(object)
        #
        # @param [ Object ] object The object to cast.
        #
        # @return [ Hash ] The converted object.
        #
        # @since 3.0.0
        def serialize(object)
          return object unless object
          ::Hash[object]
        end
      end
    end
  end
end
