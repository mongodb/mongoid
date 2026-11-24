# frozen_string_literal: true

module Mongoid
  module Errors
    # This error is raised when two models writing to the same namespace
    # describe a field, or the collection metadata, differently. The schema map
    # has one entry per namespace, so the two descriptions cannot both be
    # honored.
    class InvalidEncryptionSchema < MongoidError
      # Create the new error.
      #
      # @example Create the error.
      #   InvalidEncryptionSchema.new('music.bands', 'properties.code')
      #
      # @param [ String | nil ] namespace The namespace being described.
      # @param [ String ] path The conflicting path in the schema.
      def initialize(namespace, path)
        super(
          compose_message(
            'invalid_encryption_schema',
            { namespace: namespace || 'the collection', path: path }
          )
        )
      end
    end
  end
end
