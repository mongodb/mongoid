# frozen_string_literal: true

require 'lite_spec_helper'

MODELS = File.join(File.dirname(__FILE__), "app/models")
$LOAD_PATH.unshift(MODELS)

require "action_controller"
require 'rspec/retry'

if SpecConfig.instance.client_debug?
  Mongoid.logger.level = Logger::DEBUG
  Mongo::Logger.logger.level = Logger::DEBUG
else
  Mongoid.logger.level = Logger::INFO
  Mongo::Logger.logger.level = Logger::INFO
end

# When testing locally we use the database named mongoid_test. However when
# tests are running in parallel on Travis we need to use different database
# names for each process running since we do not have transactions and want a
# clean slate before each spec run.
def database_id
  "mongoid_test"
end

def database_id_alt
  "mongoid_test_alt"
end

require 'support/authorization'
require 'support/expectations'

# Give MongoDB time to start up on the travis ci environment.
if (ENV['CI'] == 'travis' || ENV['CI'] == 'evergreen')
  starting = true
  client = Mongo::Client.new(SpecConfig.instance.addresses)
  while starting
    begin
      client.command(Mongo::Server::Monitor::Connection::ISMASTER)
      break
    rescue Mongo::Error::OperationFailure => e
      sleep(2)
      client.cluster.scan!
    end
  end
end

CONFIG = {
  clients: {
    default: {
      database: database_id,
      hosts: SpecConfig.instance.addresses,
      options: {
        server_selection_timeout:
          if SpecConfig.instance.jruby?
            3
          else
            0.5
          end,
        wait_queue_timeout: 5,
        max_pool_size: 5,
        heartbeat_frequency: 180,
        user: MONGOID_ROOT_USER.name,
        password: MONGOID_ROOT_USER.password,
        auth_source: Mongo::Database::ADMIN,
      }
    }
  },
  options: {
    belongs_to_required_by_default: false,
    log_level: if SpecConfig.instance.client_debug?
      :debug
    else
      :info
    end,
  }
}

def non_legacy_server?
  Mongoid::Clients.default.cluster.servers.first.features.write_command_enabled?
end

def testing_replica_set?
  Mongoid::Clients.default.cluster.replica_set?
end

def collation_supported?
  Mongoid::Clients.default.cluster.next_primary.features.collation_enabled?
end
alias :decimal128_supported? :collation_supported?

def array_filters_supported?
  Mongoid::Clients.default.cluster.next_primary.features.array_filters_enabled?
end
alias :sessions_supported? :array_filters_supported?

def testing_geo_near?
  $geo_near_enabled ||= (Mongoid::Clients.default
                             .command(serverStatus: 1)
                             .first['version'] < '4.1')
end

def transactions_supported?
  Mongoid::Clients.default.cluster.next_primary.features.transactions_enabled?
end

def testing_transactions?
  transactions_supported? && testing_replica_set?
end

def testing_locally?
  !(ENV['CI'] == 'travis')
end

# Set the database that the spec suite connects to.
Mongoid.configure do |config|
  config.load_configuration(CONFIG)
end

# Autoload every model for the test suite that sits in spec/app/models.
Dir[ File.join(MODELS, "*.rb") ].sort.each do |file|
  name = File.basename(file, ".rb")
  autoload name.camelize.to_sym, name
end

module Rails
  class Application
  end
end

module MyApp
  class Application < Rails::Application
  end
end

module Mongoid
  class Query
    include Mongoid::Criteria::Queryable
  end
end

ActiveSupport::Inflector.inflections do |inflect|
  inflect.irregular("canvas", "canvases")
  inflect.singular("address_components", "address_component")
end

I18n.config.enforce_available_locales = false

RSpec.configure do |config|
  config.raise_errors_for_deprecations!
  config.include(Mongoid::Expectations)

  config.before(:suite) do
    client = Mongo::Client.new(SpecConfig.instance.addresses)
    begin
      # Create the root user administrator as the first user to be added to the
      # database. This user will need to be authenticated in order to add any
      # more users to any other databases.
      client.database.users.create(MONGOID_ROOT_USER)
    rescue Exception => e
    end
    Mongoid.purge!
  end

  # Drop all collections and clear the identity map before each spec.
  config.before(:each) do
    Mongoid.default_client.collections.each do |coll|
      coll.delete_many
    end
  end
end

# A subscriber to be used with the Ruby driver for testing.
#
# @since 6.4.0
class EventSubscriber

  # The started events.
  #
  # @since 6.4.0
  attr_reader :started_events

  # The succeeded events.
  #
  # @since 6.4.0
  attr_reader :succeeded_events

  # The failed events.
  #
  # @since 6.4.0
  attr_reader :failed_events

  # Create the test event subscriber.
  #
  # @example Create the subscriber
  #   EventSubscriber.new
  #
  # @since 6.4.0
  def initialize
    @started_events = []
    @succeeded_events = []
    @failed_events = []
  end

  # Cache the succeeded event.
  #
  # @param [ Event ] event The event.
  #
  # @since 6.4.0
  def succeeded(event)
    @succeeded_events.push(event)
  end

  # Cache the started event.
  #
  # @param [ Event ] event The event.
  #
  # @since 6.4.0
  def started(event)
    @started_events.push(event)
  end

  # Cache the failed event.
  #
  # @param [ Event ] event The event.
  #
  # @since 6.4.0
  def failed(event)
    @failed_events.push(event)
  end

  # Clear all cached events.
  #
  # @since 6.4.0
  def clear_events!
    @started_events = []
    @succeeded_events = []
    @failed_events = []
  end
end
