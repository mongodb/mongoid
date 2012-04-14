# encoding: utf-8
module Mongoid
  module Fields
    module Internal

      # Defines the behaviour for boolean fields.
      class Boolean
        include Serializable

        MAPPINGS = {
          true => true,
          "true" => true,
          "TRUE" => true,
          "1" => true,
          1 => true,
          1.0 => true,
          false => false,
          "false" => false,
          "FALSE" => false,
          "0" => false,
          0 => false,
          0.0 => false,
          nil => nil
        }

        # Serialize the object from the type defined in the model to a MongoDB
        # compatible object to store.
        #
        # @example Serialize the field.
        #   field.serialize(object)
        #
        # @param [ Object ] object The object to cast.
        #
        # @return [ true, false ] The converted boolean.
        #
        # @since 2.1.0
        def serialize(object)
          MAPPINGS.has_key?(object) ? MAPPINGS[object] : false
        end
      end
    end
  end
end
