# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Errors

    # Raised when invalid arguments are passed to #find.
    class InvalidFind < MongoidError

      # Create the new invalid find error.
      #
      # @example Create the error.
      #   InvalidFind.new
      #
      # @since 2.2.0
      def initialize(msg = nil)
        msg ||= compose_message("calling_document_find_with_nil_is_invalid", {})
        super(msg)
      end
    end
  end
end
