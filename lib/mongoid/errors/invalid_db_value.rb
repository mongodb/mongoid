# frozen_string_literal: true

module Mongoid
  module Errors

    # This error is raised when trying to retrieve an attribute with an invalid value.
    class InvalidDBValue < MongoidError

      # Create the new error.
      #
      # @param [ BSON::ObjectId ] _id The ObjectId of the field.
      # @param [ Class ] field_class The class of the field attempting to be
      #   assigned to.
      # @param [ Object ] value The value being assigned.
      #
      # @api private
      def initialize(_id, field_class, value)
        super(
          compose_message("invalid_db_value", { _id: _id, value: value, field_class: field_class  })
        )
      end
    end
  end
end
