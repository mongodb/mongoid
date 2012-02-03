$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

MODELS = File.join(File.dirname(__FILE__), "app/models")
SUPPORT = File.join(File.dirname(__FILE__), "support")
$LOAD_PATH.unshift(MODELS)
$LOAD_PATH.unshift(SUPPORT)

require "mongoid"
require "mocha"
require "rspec"
require "ammeter/init"

# These environment variables can be set if wanting to test against a database
# that is not on the local machine.
ENV["MONGOID_SPEC_HOST"] ||= "localhost"
ENV["MONGOID_SPEC_PORT"] ||= "27017"

# These are used when creating any connection in the test suite.
HOST = ENV["MONGOID_SPEC_HOST"]
PORT = ENV["MONGOID_SPEC_PORT"].to_i

# Moped.logger.level = Logger::DEBUG

# When testing locally we use the database named mongoid_test. However when
# tests are running in parallel on Travis we need to use different database
# names for each process running since we do not have transactions and want a
# clean slate before each spec run.
def database_id
  ENV["CI"] ? "mongoid_#{Process.pid}" : "mongoid_test"
end

# Set the database that the spec suite connects to.
Mongoid.configure do |config|
  config.connect_to(database_id)
end

# Autoload every model for the test suite that sits in spec/app/models.
Dir[ File.join(MODELS, "*.rb") ].sort.each do |file|
  name = File.basename(file, ".rb")
  autoload name.camelize.to_sym, name
end

# Require everything in spec/support.
Dir[ File.join(SUPPORT, "*.rb") ].each do |file|
  require File.basename(file)
end

module Rails
  class Application
  end
end

module MyApp
  class Application < Rails::Application
  end
end

RSpec.configure do |config|

  # Mocha's syntax is preferred to RSpec.
  config.mock_with(:mocha)

  # Drop all collections and clear the identity map before each spec.
  config.before(:each) do
    Mongoid.purge!
    Mongoid::IdentityMap.clear
  end

  # On travis we are creating many different databases on each test run. We
  # drop the database after the suite.
  config.after(:suite) do
    if ENV["CI"]
      Mongoid::Threaded.sessions[:default].drop
    end
  end

  # We filter out specs that require authentication to MongoHQ if the
  # environment variables have not been set up locally.
  # mongohq_configured = Support::MongoHQ.configured?
  # warn(Support::MongoHQ.message) unless mongohq_configured

  # config.filter_run_excluding(:config => lambda { |value|
    # return true if value == :mongohq && !mongohq_configured
  # })
end

ActiveSupport::Inflector.inflections do |inflect|
  inflect.singular("address_components", "address_component")
end
