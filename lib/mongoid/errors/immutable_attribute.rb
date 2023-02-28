# frozen_string_literal: true

module Mongoid
  module Errors

    # This error is raised when attempting the change the value of an
    # immutable attribute. For example, the _id attribute is immutable,
    # and attempting to change it on a document that has already been
    # persisted will result in this error.
    class ImmutableAttribute < MongoidError

      # Create the new error.
      #
      # @example Create the new error.
      #   ImmutableAttribute.new(:_id, "1234")
      #
      # @param [ Symbol | String ] name The name of the attribute.
      # @param [ Object ] value The attempted set value.
      def initialize(name, value)
        super(
          compose_message("immutable_attribute", { name: name, value: value })
        )
      end
    end
  end
end
