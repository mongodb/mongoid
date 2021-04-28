# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Errors

    # This error is raised when attempting to destroy a model which has
    # an association with dependency option set to restrict.
    class DeleteRestriction < MongoidError

      # Create the new callbacks error.
      #
      # @param [ Document ] document The document that was attempted to be
      #   destroyed.
      # @param [ Symbol ] association_name The name of the dependent
      #   association that prevents the document from being deleted.
      #
      # @since 3.0.0
      def initialize(document, association_name)
        super(
          compose_message(
            "delete_restriction",
            { document: document.class, relation: association_name }
          )
        )
      end
    end
  end
end
