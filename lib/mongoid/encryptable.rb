# rubocop:todo all
module Mongoid
  # This module is used to extend Mongoid::Document
  # to add encryption functionality.
  module Encryptable
    extend ActiveSupport::Concern

    included do
      # @return [Hash] The encryption metadata for the model.
      class_attribute :encrypt_metadata
      self.encrypt_metadata = {}
    end

    module ClassMethods
      # Set the encryption metadata for the model. Parameters set here will be
      # used to encrypt the fields of the model, unless overridden on the
      # field itself.
      #
      # @param [ Hash ] options The encryption metadata.
      # @option options [ String ] :key_id The base64-encoded UUID of the key
      #   used to encrypt fields. Mutually exclusive with :key_name_field option.
      # @option options [ String ] :key_name_field The name of the field that
      #   contains the key alt name to use for encryption. Mutually exclusive
      #   with :key_id option.
      # @option options [ true | false ] :deterministic Whether the encryption
      # is deterministic or not.
      def encrypt_with(options = {})
        self.encrypt_metadata = options
      end

      # Whether the model is encrypted. It means that either the encrypt_with
      # method was called on the model, or at least one of the fields
      # is encrypted.
      #
      # @return [ true | false ] Whether the model is encrypted.
      def encrypted?
        !encrypt_metadata.empty? || fields.any? { |_, field| field.is_a?(Mongoid::Fields::Encrypted) }
      end

      # Override the key_id for the model.
      #
      # This method is solely for testing purposes and should not be used in
      # the application code. The schema_map is generated very early in the
      # application lifecycle, and overriding the key_id after that will not
      # have any effect.
      #
      # @api private
      def set_key_id(key_id)
        self.encrypt_metadata[:key_id] = key_id
      end
    end
  end
end
