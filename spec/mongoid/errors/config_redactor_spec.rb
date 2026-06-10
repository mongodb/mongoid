# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Errors::ConfigRedactor do
  describe '.redact' do
    subject(:redacted) { described_class.redact(config) }

    context 'when the config is not a hash' do
      let(:config) { 'not a hash' }

      it 'returns the value unchanged' do
        expect(redacted).to eq('not a hash')
      end
    end

    context 'when the config has a :password key' do
      let(:config) { { hosts: [ 'localhost:27017' ], password: 's3cr3t' } }

      it 'replaces the password value' do
        expect(redacted[:password]).to eq('[REDACTED]')
      end

      it 'leaves other values intact' do
        expect(redacted[:hosts]).to eq([ 'localhost:27017' ])
      end
    end

    context 'when the config has a string "password" key' do
      let(:config) { { 'password' => 's3cr3t' } }

      it 'replaces the password value' do
        expect(redacted['password']).to eq('[REDACTED]')
      end
    end

    context 'when the config has a :uri with embedded credentials' do
      let(:config) { { uri: 'mongodb://admin:s3cr3t@cluster.example.com/db' } }

      it 'strips the userinfo from the URI' do
        expect(redacted[:uri]).to eq('mongodb://[REDACTED]@cluster.example.com/db')
      end
    end

    context 'when the config has a mongodb+srv URI' do
      let(:config) { { uri: 'mongodb+srv://admin:s3cr3t@cluster.example.com/db' } }

      it 'strips the userinfo from the URI' do
        expect(redacted[:uri]).to eq('mongodb+srv://[REDACTED]@cluster.example.com/db')
      end
    end

    context 'when the URI has no userinfo' do
      let(:config) { { uri: 'mongodb://cluster.example.com/db' } }

      it 'leaves the URI unchanged' do
        expect(redacted[:uri]).to eq('mongodb://cluster.example.com/db')
      end
    end

    context 'when the URI value is not a string' do
      let(:config) { { uri: nil } }

      it 'leaves the value unchanged' do
        expect(redacted[:uri]).to be_nil
      end
    end

    context 'when the config has nested auto_encryption_options' do
      let(:kms) do
        {
          aws: { access_key_id: 'AKIA...', secret_access_key: 'secret-value' },
          local: { key: 'A' * 96 }
        }
      end
      let(:config) do
        {
          database: 'mongoid_test',
          options: {
            auto_encryption_options: {
              key_vault_namespace: 'admin.datakeys',
              kms_providers: kms
            }
          }
        }
      end

      it 'redacts the entire auto_encryption_options value' do
        expect(redacted[:options][:auto_encryption_options]).to eq('[REDACTED]')
      end

      it 'preserves sibling values in the parent hash' do
        expect(redacted[:database]).to eq('mongoid_test')
      end

      it 'does not contain any kms secret in its serialized form' do
        expect(redacted.to_s).not_to include('secret-value')
        expect(redacted.to_s).not_to include('AKIA')
        expect(redacted.to_s).not_to include('A' * 96)
      end
    end

    context 'when redaction would mutate the input' do
      let(:config) { { password: 's3cr3t', options: { foo: 'bar' } } }

      it 'does not modify the original hash' do
        described_class.redact(config)
        expect(config[:password]).to eq('s3cr3t')
      end
    end
  end
end
