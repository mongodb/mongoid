# encoding: utf-8
module Mongoid #:nodoc:
  module Fields #:nodoc:
    module Internal #:nodoc:

      # Defines the behaviour for range fields.
      class Range
        include Serializable

        # Deserialize this field from the type stored in MongoDB to the type
        # defined on the model.
        #
        # @example Deserialize the field.
        #   field.deserialize(object)
        #
        # @param [ Object ] object The object to cast.
        #
        # @return [ Range ] The converted range.
        #
        # @since 2.1.0
        def deserialize(object)
          object.nil? ? nil : ::Range.new(object["min"], object["max"])
        end

        # Convert the provided object to a Mongoid criteria friendly value. For
        # ranges this will look for something between the min and max values.
        #
        # @example Convert the field.
        #   field.selection(object)
        #
        # @param [ Object ] The object to convert.
        #
        # @return [ Object ] The converted object.
        #
        # @since 2.4.0
        def selection(object)
          return object if object.is_a?(::Hash)
          {
            "min" => { "$gte" => object.first },
            "max" => { "$lte" => object.last }
          }
        end

        # Serialize the object from the type defined in the model to a MongoDB
        # compatible object to store.
        #
        # @example Serialize the field.
        #   field.serialize(object)
        #
        # @param [ Object ] object The object to cast.
        #
        # @return [ Hash ] The converted hash.
        #
        # @since 2.1.0
        def serialize(object)
          object.nil? ? nil : { "min" => object.first, "max" => object.last }
        end
      end
    end
  end
end
