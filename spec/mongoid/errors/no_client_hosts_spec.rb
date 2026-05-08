# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Errors::NoClientHosts do
  describe '#message' do
    let(:error) do
      described_class.new(:analytics, { database: 'mongoid_test' })
    end

    it 'contains the problem in the message' do
      expect(error.message).to include(
        'No hosts provided for client configuration: :analytics.'
      )
    end

    it 'contains the summary in the message' do
      expect(error.message).to include(
        'Each client configuration must provide hosts so Mongoid'
      )
    end

    it 'contains the resolution in the message' do
      expect(error.message).to include(
        'If configuring via a mongoid.yml, ensure that within your :analytics'
      )
    end

    context 'when the config contains sensitive values' do
      let(:error) do
        described_class.new(
          :analytics,
          {
            database: 'mongoid_test',
            password: 's3cr3t',
            options: {
              auto_encryption_options: {
                kms_providers: { local: { key: 'A' * 96 } }
              }
            }
          }
        )
      end

      it 'redacts the password value' do
        expect(error.message).not_to include('s3cr3t')
      end

      it 'redacts auto_encryption_options entirely' do
        expect(error.message).not_to include('kms_providers')
        expect(error.message).not_to include('A' * 96)
      end
    end
  end
end
