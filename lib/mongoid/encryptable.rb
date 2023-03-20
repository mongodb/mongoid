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
      #   used to encrypt fields.
      # @option options [ true | false ] :deterministic Whether the encryption
      # is deterministic or not.
      def encrypt_with(options = {})
        self.encrypt_metadata = options
      end
    end
  end
end
