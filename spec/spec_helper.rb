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

Mongoid.configure do |config|
  config.master = Mongo::Connection.new.db("mongoid_test")
  config.logger = nil
end

Dir[ File.join(MODELS, "*.rb") ].sort.each { |file| require File.basename(file) }
Dir[ File.join(SUPPORT, "*.rb") ].each { |file| require File.basename(file) }

RSpec.configure do |config|
  config.mock_with(:mocha)

  config.after(:suite) { Mongoid.purge! }
  config.before(:each) { Mongoid::IdentityMap.clear }

  # We filter out the specs that require authentication if the database has not
  # had the mongoid user set up properly.
  user_configured = Support::Authentication.configured?
  warn(Support::Authentication.message) unless user_configured

  # We filter out specs that require authentication to MongoHQ if the
  # environment variables have not been set up locally.
  mongohq_configured = Support::MongoHQ.configured?
  warn(Support::MongoHQ.message) unless mongohq_configured

  config.filter_run_excluding(:config => lambda { |value|
    return true if value == :mongohq && !mongohq_configured
    return true if value == :user && !user_configured
  })
end

ActiveSupport::Inflector.inflections do |inflect|
  inflect.singular("address_components", "address_component")
end
