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

LOGGER = Logger.new($stdout)
DATABASE_ID = Process.pid

Mongoid.configure do |config|
  database = Mongo::Connection.new.db("mongoid_#{DATABASE_ID}")
  database.add_user("mongoid", "test")
  config.master = database
  config.logger = nil
end

Dir[ File.join(MODELS, "*.rb") ].sort.each do |file|
  name = File.basename(file, ".rb")
  autoload name.camelize.to_sym, name
end

module Medical
  autoload :Patient, "medical/patient"
  autoload :Prescription, "medical/prescription"
end

module MyCompany
  module Model
    autoload :TrackingId, "my_company/model/tracking_id"
    autoload :TrackingIdValidationHistory, "my_company/model/tracking_id_validation_history"
  end
end

module Trees
  autoload :Node, "trees/node"
end

module Custom
  autoload :String, "custom/string"
  autoload :Type, "custom/type"
end

module Mongoid
  module MyExtension
    autoload :Object, "mongoid/my_extension/object"
  end
end

Dir[ File.join(SUPPORT, "*.rb") ].each do |file|
  require File.basename(file)
end

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
