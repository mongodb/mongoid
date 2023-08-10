# frozen_string_literal: true

module Mongoid
  module Railties
    module ActiveJobSerializers
      # This class provides serialization and deserialization of BSON::ObjectId
      # for ActiveJob.
      #
      # It is important that this class is loaded only when Rails is available
      # since it depends on Rails' ActiveJob::Serializers::ObjectSerializer.
      class BsonObjectIdSerializer < ActiveJob::Serializers::ObjectSerializer
        #  Returns whether the argument can be serialized by this serializer.
        #
        #  @param [ Object ] argument The argument to check.
        #
        #  @return [ true | false ] Whether the argument can be serialized.
        def serialize?(argument)
          argument.is_a?(BSON::ObjectId)
        end

        # Serializes the argument to be passed to the job.
        #
        # @param [ BSON::ObjectId ] object The object to serialize.
        def serialize(object)
          object.to_s
        end

        # Deserializes the argument back into a BSON::ObjectId.
        #
        # @param [ String ] string The string to deserialize.
        #
        # @return [ BSON::ObjectId ] The deserialized object.
        def deserialize(string)
          BSON::ObjectId.from_string(string)
        end
      end
    end
  end
end
