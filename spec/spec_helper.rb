$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

MODELS = File.join(File.dirname(__FILE__), "app/models")
SUPPORT = File.join(File.dirname(__FILE__), "support")
$LOAD_PATH.unshift(MODELS)
$LOAD_PATH.unshift(SUPPORT)

require "mongoid"
require "mocha"
require "rspec"

LOGGER = Logger.new($stdout)
DATABASE_ID = Process.pid

Mongoid.configure do |config|
  database = Mongo::Connection.new.db("mongoid_#{DATABASE_ID}")
  database.add_user("mongoid", "test")
  config.master = database
  config.logger = nil
end

Dir[ File.join(MODELS, "*.rb") ].sort.each { |file| require File.basename(file) }
Dir[ File.join(SUPPORT, "*.rb") ].each { |file| require File.basename(file) }

RSpec.configure do |config|
  config.mock_with(:mocha)

  config.before(:each) do
    Mongoid::IdentityMap.clear
  end

  config.after(:suite) do
    Mongoid.master.connection.drop_database("mongoid_#{DATABASE_ID}")
  end

  # We filter out specs that require authentication to MongoHQ if the
  # environment variables have not been set up locally.
  mongohq_configured = Support::MongoHQ.configured?
  warn(Support::MongoHQ.message) unless mongohq_configured

  config.filter_run_excluding(:config => lambda { |value|
    return true if value == :mongohq && !mongohq_configured
  })
end

ActiveSupport::Inflector.inflections do |inflect|
  inflect.singular("address_components", "address_component")
end
