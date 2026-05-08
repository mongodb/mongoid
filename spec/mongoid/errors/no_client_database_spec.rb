# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Errors::NoClientDatabase do
  describe '#message' do
    let(:error) do
      described_class.new(:analytics, { hosts: [ '127.0.0.1:27017' ] })
    end

    it 'contains the problem in the message' do
      expect(error.message).to include(
        'No database provided for client configuration: :analytics.'
      )
    end

    it 'contains the summary in the message' do
      expect(error.message).to include(
        'Each client configuration must provide a database so Mongoid'
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
            hosts: [ '127.0.0.1:27017' ],
            password: 's3cr3t',
            options: {
              auto_encryption_options: {
                kms_providers: {
                  aws: { access_key_id: 'AKIAEXAMPLE', secret_access_key: 'aws-secret' }
                }
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
        expect(error.message).not_to include('aws-secret')
        expect(error.message).not_to include('AKIAEXAMPLE')
      end
    end
  end
end
