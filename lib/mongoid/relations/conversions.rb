# encoding: utf-8
module Mongoid
  module Relations

    # Contains utility methods for object id conversion.
    module Conversions
      extend self

      # Mark the provided object as unconvertable to bson or not, and always
      # return the provided object.
      #
      # @example Flag the object.
      #   Conversions.flag(metadata, 15)
      #
      # @param [ Object ] object The object to flag.
      # @param [ Metadata ] The relation metadata.
      #
      # @return [ Object ] The provided object.
      #
      # @since 2.3.0
      def flag(object, metadata)
        inverse = metadata.inverse_klass
        if inverse.using_object_ids? || object.is_a?(Moped::BSON::ObjectId)
          object
        else
          if object.is_a?(String)
            object.unconvertable_to_bson = true
          end
          object
        end
      end
    end
  end
end
