# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module Tasks
    # This module contains helper methods for data encryption.
    module Encryption
      extend self

      # Create a data encryption key for the given kms provider using the
      # auto_encryption_options from the client's configuration.
      #
      # @param [ String | nil ] kms_provider_name The name of the kms provider
      #   to use. If not provided, the first provider in the client's
      #   auto_encryption_options will be used.
      # @param [ String | nil ] client_name The name of the client to take
      #   auto_encryption_options from. If not provided, the default client
      #   will be used.
      # @param [ String | nil ] key_alt_name The alternate name of the key.
      #
      # @return [ Hash ] A hash containing the key id as :key_id,
      #   kms provider name as :kms_provider, and key vault namespace as
      #   :key_vault_namespace.
      def create_data_key(client_name: nil, kms_provider_name: nil, key_alt_name: nil)
        kms_provider_name, kms_providers, key_vault_namespace = prepare_arguments(
          kms_provider_name,
          client_name
        )
        key_vault_client = Mongoid::Clients.default.with(database: key_vault_namespace.split('.').first)
        client_encryption = Mongo::ClientEncryption.new(
          key_vault_client,
          key_vault_namespace: key_vault_namespace,
          kms_providers: kms_providers
        )
        client_encryption_opts = {}.tap do |opts|
          opts[:key_alt_names] = [key_alt_name] if key_alt_name
        end
        data_key_id = client_encryption.create_data_key(kms_provider_name, client_encryption_opts)
        {
          key_id: Base64.strict_encode64(data_key_id.data),
          kms_provider: kms_provider_name,
          key_vault_namespace: key_vault_namespace,
          key_alt_name: key_alt_name
        }.compact
      end

      private

      # Prepare arguments needed to create a data key from the client's
      # auto_encryption_options.
      #
      # @param [ String | nil ] kms_provider_name The name of the kms provider.
      # @param [ String | nil ] client_name The name of the client.
      #
      # @return [ Array<String, Hash, String> ] An array containing the
      #   normalized kms provider name, the kms providers hash, and the key
      #   vault namespace.
      def prepare_arguments(kms_provider_name, client_name)
        client = (client_name || 'default').to_s
        client_options = Mongoid.clients[client]
        unless client_options.is_a?(Hash)
          raise Errors::NoClientConfig.new(client)
        end
        auto_encryption_options = client_options.dig(:options, :auto_encryption_options)
        unless auto_encryption_options.is_a?(Hash)
          raise Errors::InvalidAutoEncryptionConfiguration.new(client)
        end
        key_vault_namespace = auto_encryption_options[:key_vault_namespace]
        unless key_vault_namespace.is_a?(String)
          raise Errors::InvalidAutoEncryptionConfiguration.new(client)
        end
        kms_providers = auto_encryption_options[:kms_providers]
        unless kms_providers.is_a?(Hash)
          raise Errors::InvalidAutoEncryptionConfiguration.new(client)
        end
        valid_kms_provider_name = get_kms_provider_name(kms_provider_name, kms_providers)
        unless kms_providers.key?(valid_kms_provider_name)
          raise Errors::InvalidAutoEncryptionConfiguration.new(client, valid_kms_provider_name)
        end

        [valid_kms_provider_name, kms_providers, key_vault_namespace]
      end

      # Get kms provider name to use for creating a data key.
      #
      # If kms_provider_name is provided, it will be used. Otherwise, if there
      # is only one kms provider, that provider will be used. Otherwise, an
      # error will be raised.
      #
      # @param [ String | nil ] kms_provider_name The name of the kms provider
      #   as provided by the user.
      # @param [ Hash ] kms_providers The kms providers hash from the client's
      #   auto_encryption_options.
      #
      # @return [ String ] The kms provider name to use for creating a data
      #   key.
      def get_kms_provider_name(kms_provider_name, kms_providers)
        if kms_provider_name
          kms_provider_name
        elsif kms_providers.keys.length == 1
          kms_providers.keys.first
        else
          raise ArgumentError, 'kms_provider_name must be provided when there are multiple kms providers'
        end
      end
    end
  end
end
