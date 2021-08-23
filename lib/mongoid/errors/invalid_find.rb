# frozen_string_literal: true

module Mongoid
  module Errors

    # Raised when invalid arguments are passed to #find.
    class InvalidFind < MongoidError

      # Create the new invalid find error.
      #
      # @example Create the error.
      #   InvalidFind.new
      def initialize
        super(compose_message("calling_document_find_with_nil_is_invalid", {}))
      end
    end
  end
end
