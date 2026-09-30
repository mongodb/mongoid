# frozen_string_literal: true

module Mongoid
  module Errors
    # This error is raised when a model declares encrypted fields, but the
    # namespace it is about to be persisted to is not covered by the automatic
    # encryption schema of the client in use. Without a schema the driver has
    # nothing to encrypt with, and the fields would be stored in plaintext.
    class NoEncryptionSchema < MongoidError
      # Create the new error.
      #
      # @example Create the error.
      #   NoEncryptionSchema.new(Band, 'music.bands', :default)
      #
      # @param [ Class ] klass The model class.
      # @param [ String ] namespace The namespace the model resolved to.
      # @param [ String | Symbol ] client The name of the client in use.
      def initialize(klass, namespace, client)
        super(
          compose_message(
            'no_encryption_schema',
            { klass: klass, namespace: namespace, client: client }
          )
        )
      end
    end
  end
end
