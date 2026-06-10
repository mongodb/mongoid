# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Errors::MixedClientConfiguration do
  describe '#message' do
    let(:error) do
      described_class.new(:testing, { uri: 'blah' })
    end

    it 'contains the problem in the message' do
      expect(error.message).to include(
        'Both uri and standard configuration options defined'
      )
    end

    it 'contains the summary in the message' do
      expect(error.message).to include(
        'Instead of simply giving uri or standard options a preference'
      )
    end

    it 'contains the resolution in the message' do
      expect(error.message).to include(
        'Provide either only a uri as configuration'
      )
    end

    context 'when the config contains sensitive values' do
      let(:error) do
        described_class.new(
          :testing,
          {
            uri: 'mongodb://admin:s3cr3t@cluster.example.com/db',
            password: 'standalone-secret',
            options: {
              auto_encryption_options: {
                kms_providers: { local: { key: 'A' * 96 } }
              }
            }
          }
        )
      end

      it 'redacts the URI userinfo' do
        expect(error.message).not_to include('admin:s3cr3t')
        expect(error.message).to include('mongodb://[REDACTED]@cluster.example.com/db')
      end

      it 'redacts the standalone password value' do
        expect(error.message).not_to include('standalone-secret')
      end

      it 'redacts auto_encryption_options entirely' do
        expect(error.message).not_to include('kms_providers')
        expect(error.message).not_to include('A' * 96)
      end
    end
  end
end
