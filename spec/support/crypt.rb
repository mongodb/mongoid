# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  # This module includes helpers for testing encryption.
  module Crypt

    shared_context 'with encryption' do
      let(:mongocryptd_port) do
        if ENV['MONGO_RUBY_DRIVER_MONGOCRYPTD_PORT'] &&
          !ENV['MONGO_RUBY_DRIVER_MONGOCRYPTD_PORT'].empty?
        then
          ENV['MONGO_RUBY_DRIVER_MONGOCRYPTD_PORT'].to_i
        else
          27020
        end
      end

      let(:extra_options) do
        {
          mongocryptd_spawn_args: ["--port=#{mongocryptd_port}"],
          mongocryptd_uri: "mongodb://localhost:#{mongocryptd_port}",
        }
      end

      let(:crypt_shared_lib_path) do
        ENV['MONGO_RUBY_DRIVER_CRYPT_SHARED_LIB_PATH']
      end

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
          key_id = client_encryption.create_data_key('local', key_alt_names: [key_alt_name])
          Base64.encode64(key_id.data).strip
        end
      end
    end
  end
end
