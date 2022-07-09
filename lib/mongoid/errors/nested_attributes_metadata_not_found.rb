# frozen_string_literal: true

module Mongoid
  module Errors

    # This error is raised when metadata could not be found when defining
    # nested attributes, or the name was incorrect.
    class NestedAttributesMetadataNotFound < MongoidError

      # Create the new metadata error.
      #
      # @example Create the new metadata error.
      #   NestedAttributesMetadataNotFound.new(klass, name)
      #
      # @param [ Class ] klass The class of the document.
      # @param [ Symbol | String ] name The name of the association
      def initialize(klass, name)
        super(
          compose_message(
            "nested_attributes_metadata_not_found",
            { klass: klass, name: name }
          )
        )
      end
    end
  end
end
