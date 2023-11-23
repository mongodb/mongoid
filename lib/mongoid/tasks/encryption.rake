# frozen_string_literal: true

require 'optparse'

def parse_data_key_options(argv = ARGV)
  # The only way to use OptionParser to parse custom options in rake is
  # to pass an empty argument ("--") before specifying them, e.g.:
  #
  #    rake db:mongoid:encryption:create_data_key -- --client default
  #
  # Otherwise, rake complains about an unknown option. Thus, we can tell
  # if the argument list is valid for us to parse by detecting this empty
  # argument.
  #
  # (This works around an issue in the tests, where the specs are loading
  # the tasks directly to test them, but the option parser is then picking
  # up rspec command-line arguments and raising an exception).
  return {} unless argv.include?('--')

  {}.tap do |options|
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
    parser.parse!(parser.order!(argv) {})
    # rubocop:enable Lint/EmptyBlock
  end
end

namespace :db do
  namespace :mongoid do
    namespace :encryption do
      desc 'Create encryption key'
      task create_data_key: [ :environment ] do
        options = parse_data_key_options
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
