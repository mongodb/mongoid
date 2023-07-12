# frozen_string_literal: true

require 'optparse'

# rubocop:disable Metrics/BlockLength
namespace :db do
  namespace :mongoid do
    namespace :encryption do
      desc 'Create encryption key'
      task create_data_key: [ :environment ] do
        options = {}
        parser = OptionParser.new do |opts|
          opts.on('-c', '--client CLIENT', 'Name of the client to use') do |v|
            options[:client_name] = v
          end
          opts.on('-p', '--provider PROVIDER', 'KMS provider to use') do |v|
            options[:kms_provider_name] = v
          end
          opts.on('-n', '--key-alt-name KEY_ALT_NAME', 'Alternate name for the key') do |v|
            options[:key_alt_name] = v
          end
        end
        # rubocop:disable Lint/EmptyBlock
        parser.parse!(parser.order!(ARGV) {})
        # rubocop:enable Lint/EmptyBlock
        result = Mongoid::Tasks::Encryption.create_data_key(
          client_name: options[:client_name],
          kms_provider_name: options[:kms_provider_name],
          key_alt_name: options[:key_alt_name]
        )
        output = [].tap do |lines|
          lines << "Created data key with id: '#{result[:key_id]}'"
          lines << "with key alt name: '#{result[:key_alt_name]}'" if result[:key_alt_name]
          lines << "for kms provider: '#{result[:kms_provider]}'"
          lines << "in key vault: '#{result[:key_vault_namespace]}'."
        end
        puts output.join(' ')
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
