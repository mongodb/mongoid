# encoding: utf-8
module Mongoid #:nodoc:
  module Fields #:nodoc:
    module Internal #:nodoc:
      # Defines the behaviour for regex fields.
      class Regexp
        include Serializable

        # Serialize the object from the type defined in the model to a MongoDB
        # compatible object to store. Will attempt to convert the provided
        # value to a regex.
        #
        # @example Serialize the field.
        #   field.serialize(object)
        #
        # @param [ Object ] object The object to cast.
        #
        # @return [ String ] The converted string.
        #
        # @since 2.1.0
        def serialize(value)
          ::Regexp.new(value)
        end
      end
    end
  end
end
