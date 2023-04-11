# frozen_string_literal: true

namespace :db do
  namespace :mongoid do
    namespace :encryption do

      desc "Create encryption key"
      task :create_data_key, [:client, :provider] => [:environment] do |_t, args|
        result = ::Mongoid::Tasks::Encryption.create_data_key(
          client_name: args[:client],
          kms_provider_name: args[:provider]
        )
        puts "Created data key with id: '#{result[:key_id]}' " +
          "for kms provider: '#{result[:kms_provider]}' " +
          "in key vault: '#{result[:key_vault_namespace]}'."
      end
    end
  end
end
