# encoding: utf-8
module Mongoid
  module Associations

    # Contains utility methods for object id conversion.
    module Conversions

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
      def flag(object)
        if inverse_class.using_object_ids? || object.is_a?(BSON::ObjectId)
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
