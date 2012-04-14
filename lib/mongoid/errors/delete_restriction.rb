# encoding: utf-8
module Mongoid
  module Errors

    # This error is raised when calling #save! or .create! on a model when one
    # of the callbacks returns false.
    class DeleteRestriction < MongoidError

      # Create the new callbacks error.
      #
      # @example Create the new callbacks error.
      #   Callbacks.new(Post, :create!)
      #
      # @param [ Class ] klass The class of the document.
      # @param [ Symbol ] method The name of the method.
      #
      # @since 3.0.0
      def initialize(document, relation)
        super(
          compose_message(
            "delete_restriction",
            { document: document.class, relation: relation }
          )
        )
      end
    end
  end
end

