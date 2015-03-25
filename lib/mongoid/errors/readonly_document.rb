# encoding: utf-8
module Mongoid
  module Errors

    # Raised when attempting to persist a document that was loaded from the
    # database with partial fields.
    #
    # @since 4.0.0
    class ReadonlyDocument < MongoidError

      # Instnatiate the exception.
      #
      # @example Create the error.
      #   ReadonlyDocument.new(Band)
      #
      # @param [ Class ] klass The document class.
      #
      # @since 4.0.0
      def initialize(klass)
        super(compose_message("readonly_document", { klass: klass }))
      end
    end
  end
end
