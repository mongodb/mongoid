# encoding: utf-8
module Mongoid
  module Errors

    # Raised when attempting to destroy a document that had destory callbacks
    # return false.
    #
    # @since 4.0.0
    class DocumentNotDestroyed < MongoidError

      # Instnatiate the exception.
      #
      # @example Create the error.
      #   DocumentNotDestroyed.new(Band)
      #
      # @param [ Object ] id The document id.
      # @param [ Class ] klass The document class.
      #
      # @since 4.0.0
      def initialize(id, klass)
        super(compose_message("document_not_destroyed", { id: id.inspect, klass: klass }))
      end
    end
  end
end
