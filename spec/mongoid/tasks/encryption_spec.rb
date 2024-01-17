# frozen_string_literal: true
# rubocop:todo all

require "spec_helper"

describe "Mongoid::Tasks::Encryption" do
  require_enterprise
  require_libmongocrypt
  include_context 'with encryption'
  restore_config_clients

  describe ".create_data_key" do
    let(:config) do
      {
        default: { hosts: SpecConfig.instance.addresses, database: database_id },
        encrypted: {
          hosts: SpecConfig.instance.addresses,
          database: database_id,
          options: {
            auto_encryption_options: {
              kms_providers: kms_providers,
              key_vault_namespace: key_vault_namespace,
              extra_options: extra_options
            }
          }
        }
      }
    end

    let(:data_key_id) do
      BSON::Binary.new('data_key_id', :uuid)
    end

    let(:key_alt_name) do
      'mongoid_test_alt_name'
    end

    before do
      key_vault_client[key_vault_collection].drop
      Mongoid::Config.send(:clients=, config)
    end

    context 'when all parameters are correct' do
      context 'when all parameters are provided' do
        before do
          expect_any_instance_of(Mongo::ClientEncryption)
            .to receive(:create_data_key)
                  .with('local', { key_alt_names: [key_alt_name] })
                  .and_return(data_key_id)
        end
        it 'creates a data key' do
          result = Mongoid::Tasks::Encryption.create_data_key(
            kms_provider_name: 'local',
            client_name: :encrypted,
            key_alt_name: key_alt_name
          )
          expect(result).to eq(
            {
              key_id: Base64.strict_encode64(data_key_id.data),
              key_vault_namespace: key_vault_namespace,
              kms_provider: 'local',
              key_alt_name: key_alt_name
            }
          )
        end
      end

      context 'when kms_provider_name is not provided' do
        context 'and there is only one kms provider' do
          context 'without key_alt_name' do
            before do
              expect_any_instance_of(Mongo::ClientEncryption)
                .to receive(:create_data_key)
                      .with('local', {})
                      .and_return(data_key_id)
            end
            it 'creates a data key' do
              result = Mongoid::Tasks::Encryption.create_data_key(client_name: :encrypted)
              expect(result).to eq(
                {
                  key_id: Base64.strict_encode64(data_key_id.data),
                  key_vault_namespace: key_vault_namespace,
                  kms_provider: 'local'
                }
              )
            end
          end

          context 'with key_alt_name' do
            before do
              expect_any_instance_of(Mongo::ClientEncryption)
                .to receive(:create_data_key)
                      .with('local', {key_alt_names: [key_alt_name]})
                      .and_return(data_key_id)
            end
            it 'creates a data key' do
              result = Mongoid::Tasks::Encryption.create_data_key(
                client_name: :encrypted,
                key_alt_name: key_alt_name
              )
              expect(result).to eq(
                {
                  key_id: Base64.strict_encode64(data_key_id.data),
                  key_vault_namespace: key_vault_namespace,
                  kms_provider: 'local',
                  key_alt_name: key_alt_name
                }
              )
            end
          end
        end
      end
    end

    context 'when the client name is incorrect' do
      it 'raises an error' do
        expect {
          Mongoid::Tasks::Encryption.create_data_key(kms_provider_name: 'local', client_name: :wrong_client)
        }.to raise_error(Mongoid::Errors::NoClientConfig)
      end
    end

    context 'when the client does not have auto_encryption_options' do
      it 'raises an error' do
        expect {
          Mongoid::Tasks::Encryption.create_data_key(kms_provider_name: 'local', client_name: :default)
        }.to raise_error(Mongoid::Errors::InvalidAutoEncryptionConfiguration)
      end
    end

    context 'when key_value_namespace is not set' do
      let(:config) do
        {
          default: { hosts: SpecConfig.instance.addresses, database: database_id },
          encrypted: {
            hosts: SpecConfig.instance.addresses,
            database: database_id,
            options: {
              auto_encryption_options: {
                kms_providers: kms_providers,
                extra_options: extra_options
              }
            }
          }
        }
      end

      it 'raises an error' do
        expect {
          Mongoid::Tasks::Encryption.create_data_key(kms_provider_name: 'local', client_name: :encrypted)
        }.to raise_error(Mongoid::Errors::InvalidAutoEncryptionConfiguration)
      end
    end

    context 'when kms_providers is not set' do
      let(:config) do
        {
          default: { hosts: SpecConfig.instance.addresses, database: database_id },
          encrypted: {
            hosts: SpecConfig.instance.addresses,
            database: database_id,
            options: {
              auto_encryption_options: {
                key_vault_namespace: key_vault_namespace,
                extra_options: extra_options
              }
            }
          }
        }
      end

      it 'raises an error' do
        expect {
          Mongoid::Tasks::Encryption.create_data_key(kms_provider_name: 'local', client_name: :encrypted)
        }.to raise_error(Mongoid::Errors::InvalidAutoEncryptionConfiguration)
      end
    end

    context 'when kms_providers does not include used provider' do
      it 'raises an error' do
        expect {
          Mongoid::Tasks::Encryption.create_data_key(kms_provider_name: 'aws', client_name: :encrypted)
        }.to raise_error(Mongoid::Errors::InvalidAutoEncryptionConfiguration)
      end
    end
  end
end
