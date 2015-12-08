$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

MODELS = File.join(File.dirname(__FILE__), "app/models")
$LOAD_PATH.unshift(MODELS)

require "action_controller"
require "mongoid"
require "rspec"

# These environment variables can be set if wanting to test against a database
# that is not on the local machine.
ENV["MONGOID_SPEC_HOST"] ||= "127.0.0.1"
ENV["MONGOID_SPEC_PORT"] ||= "27017"

# These are used when creating any connection in the test suite.
HOST = ENV["MONGOID_SPEC_HOST"]
PORT = ENV["MONGOID_SPEC_PORT"].to_i

Mongo::Logger.logger.level = Logger::INFO
# Mongoid.logger.level = Logger::DEBUG

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
if (ENV['CI'] == 'travis')
  starting = true
  client = Mongo::Client.new(['127.0.0.1:27017'])
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
      hosts: [ "#{HOST}:#{PORT}" ],
      options: {
        server_selection_timeout: 0.5,
        max_pool_size: 1,
        heartbeat_frequency: 180,
        user: MONGOID_ROOT_USER.name,
        password: MONGOID_ROOT_USER.password,
        auth_source: Mongo::Database::ADMIN,
      }
    }
  }
}

def non_legacy_server?
  Mongoid::Clients.default.cluster.servers.first.features.write_command_enabled?
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

ActiveSupport::Inflector.inflections do |inflect|
  inflect.irregular("canvas", "canvases")
  inflect.singular("address_components", "address_component")
end

I18n.config.enforce_available_locales = false

RSpec.configure do |config|
  config.raise_errors_for_deprecations!
  config.include(Mongoid::Expectations)

  config.before(:suite) do
    client = Mongo::Client.new(["#{HOST}:#{PORT}"])
    begin
      # Create the root user administrator as the first user to be added to the
      # database. This user will need to be authenticated in order to add any
      # more users to any other databases.
      client.database.users.create(MONGOID_ROOT_USER)
    rescue Exception => e
    end
  end

  # Drop all collections and clear the identity map before each spec.
  config.before(:each) do
    Mongoid.purge!
  end
end
