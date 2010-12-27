$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

MODELS = File.join(File.dirname(__FILE__), "models")
$LOAD_PATH.unshift(MODELS)

require "mongoid"
require "mocha"
require "rspec"

LOGGER = Logger.new($stdout)

Mongoid.configure do |config|
  name = "mongoid_test"
  config.master = Mongo::Connection.new.db(name)
  config.logger = nil
end

Dir[ File.join(MODELS, "*.rb") ].sort.each { |file| require File.basename(file) }

Rspec.configure do |config|
  config.mock_with(:mocha)
  config.after(:suite) do
    Mongoid.master.collections.select {|c| c.name !~ /system/ }.each(&:drop)
  end

  # We need to filter out the specs that hit the slave databases if 2 slaves
  # are not confiured and running locally.
  slaves_configured = begin
    slave_one_uri = "mongodb://mongoid:test@localhost:27018/mongoid_test"
    slave_two_uri = "mongodb://mongoid:test@localhost:27019/mongoid_test"
    Mongo::Connection.from_uri(slave_one_uri, :slave_ok => true)
    Mongo::Connection.from_uri(slave_two_uri, :slave_ok => true)
    true
  rescue Mongo::ConnectionFailure => e
    false
  end

  warn(%{
The Mongoid configuration specs require 2 slave databases to be running in
order to properly be tested. Those specs are skipped when the slaves are not
running locally. Here is a sample configuration for a slave database:

dbpath = /usr/local/var/mongodb/slave
port = 27018
slave = true
bind_ip = 127.0.0.1
source = 127.0.0.1:27017
  }) unless slaves_configured

  # We filter out the specs that require authentication if the database has not
  # had the mongoid user set up properly.
  user_configured = begin
    master_uri = "mongodb://mongoid:test@localhost:27017/mongoid_test"
    Mongo::Connection.from_uri(master_uri)
    true
  rescue Mongo::AuthenticationError => e
    false
  end

  warn(%{
A user needs to be configured for authentication, otherwise some configuration
specs will not get run. You may set it up from the mongo console:

$ use mongoid_test;
$ db.addUser("mongoid", "test");
  }) unless user_configured

  # Filter out the marked specs as appropriate.
  config.filter_run_excluding(:config => lambda { |value|
    return true if value == :slaves && !slaves_configured
    return true if value == :user && !user_configured
  })
end

ActiveSupport::Inflector.inflections do |inflect|
  inflect.singular("address_components", "address_component")
end

