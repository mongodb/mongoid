# encoding: utf-8
module Mongoid #:nodoc:
  module Fields #:nodoc:
    module Standard #:nodoc:

      # Defines the behaviour for range fields.
      class Range
        include Serializable

        # When reading the field do we need to cast the value? This holds true when
        # times are stored or for big decimals which are stored as strings.
        #
        # @example Typecast on a read?
        #   field.cast_on_read?
        #
        # @return [ true ] Date fields cast on read.
        #
        # @since 2.1.0
        def cast_on_read?; true; end

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
        alias :get :deserialize

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
          object.nil? ? nil : { "min" => object.min, "max" => object.max }
        end
        alias :set :serialize
      end
    end
  end
end
