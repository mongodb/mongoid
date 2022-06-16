# frozen_string_literal: true

module Mongoid
  module Errors

    # This error is raised when trying to set an attribute with an invalid value.
    # For example when try to set an Array value to a Hash attribute.
    #
    class InvalidValue < MongoidError

      # Create the new error.
      #
      # @param [ Class ] field_class The class of the field attempting to be
      #   assigned to.
      # @param [ Object ] value The value being assigned.
      #
      # @api private
      def initialize(field_class, value)
        super(
          compose_message("invalid_value", { value: value, field_class: field_class  })
        )
      end
    end
  end
end
