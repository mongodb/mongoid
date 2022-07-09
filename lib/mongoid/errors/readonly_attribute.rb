# frozen_string_literal: true

module Mongoid
  module Errors

    # This error is raised when attempting the change the value of a readonly
    # attribute after the document has been persisted.
    class ReadonlyAttribute < MongoidError

      # Create the new error.
      #
      # @example Create the new error.
      #   ReadonlyAttribute.new(:title, "mr")
      #
      # @param [ Symbol | String ] name The name of the attribute.
      # @param [ Object ] value The attempted set value.
      def initialize(name, value)
        super(
          compose_message("readonly_attribute", { name: name, value: value })
        )
      end
    end
  end
end
