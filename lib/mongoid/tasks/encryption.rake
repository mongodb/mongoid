# frozen_string_literal: true
# rubocop:todo all

namespace :db do
  namespace :mongoid do
    namespace :encryption do

      desc "Create encryption key"
      task :create_data_key, [:client, :provider, :key_alt_name] => [:environment] do |_t, args|
        result = ::Mongoid::Tasks::Encryption.create_data_key(
          client_name: args[:client],
          kms_provider_name: args[:provider],
          key_alt_name: args[:key_alt_name]
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
