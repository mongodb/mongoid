# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module Railties
    module ActiveJobSerializers

      # This extension mimics the Rails' internal method to
      # measure ActiveRecord runtime during request processing.
      # It appends MongoDB runtime value (`mongoid_runtime`) into payload
      # of instrumentation event `process_action.action_controller`.
      #
      # @api private
      class BsonObjectIdSerializer < ::ActiveJob::Serializers::ObjectSerializer

        # Serializer BSON::ObjectId into String.
        #
        # @param [ BSON::ObjectId ] argument The deserialized object id.
        #
        # @return [ String ] The serialized object id.
        def serialize(argument)
          super('value' => argument.to_s)
        end

        # Deserialize String into BSON::ObjectId.
        #
        # @param [ String ] argument The serialized object id.
        #
        # @return [ BSON::ObjectId ] The deserialized object id.
        def deserialize(argument)
          ::BSON::ObjectId(argument['value'])
        end

        private

        def klass
          ::BSON::ObjectId
        end
      end
    end
  end
end
