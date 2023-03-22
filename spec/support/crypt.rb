# frozen_string_literal: true

module Mongoid
  # This module includes helpers for testing encryption.
  module Crypt

    shared_context 'with encryption' do
      let(:key_vault_client) do
        Mongo::Client.new(SpecConfig.instance.addresses, database: key_vault_database)
      end

      let(:key_vault_database) do
        'encryption'
      end

      let(:key_vault_collection) do
        '__keyVault'
      end

      let(:key_vault_namespace) do
        "#{key_vault_database}.#{key_vault_collection}"
      end

      let(:local_master_key) do
        'A' * 96
      end

      let(:kms_providers) do
        {
          local: {
            key: local_master_key
          }
        }
      end

      let(:key_alt_name) do
        'mongoid_test_key'
      end

      let(:client_encryption) do
        Mongo::ClientEncryption.new(
          key_vault_client,
          key_vault_namespace: key_vault_namespace,
          kms_providers: kms_providers
        )
      end

      let(:data_key_id) do
        if (data_key = client_encryption.get_key_by_alt_name(key_alt_name))
          Base64.encode64(data_key['_id'].data)
        else
          key_id = client_encryption.create_data_key('local', key_alt_name: key_alt_name)
          client_encryption.add_key_alt_name(key_id, key_alt_name)
          Base64.encode64(key_id.data)
        end
      end

      # Sets the key id for the model and all encrypted fields.
      # This method is needed because the key id is not known until the data key
      # is created. And we create the key in the spec.
      def set_key_id(model, key_id)
        model.set_key_id(key_id) if model.encrypt_metadata.key?(:key_id)
        model.fields.each do |(field_name, field)|
          if field.is_a?(Mongoid::Fields::Encrypted) && field.key_id
            field.set_key_id(key_id)
          end
        end
      end
    end
  end
end
