$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

MODELS = File.join(File.dirname(__FILE__), "models")
$LOAD_PATH.unshift(MODELS)

require 'rubygems'

gem "mocha", ">= 0.9.8"

require "mocha"
require "mongoid"
require "spec"

Mongoid.configure do |config|
  name = "mongoid_test"
  config.database = Mongo::Connection.new.db(name)
  # config.master = Mongo::Connection.new(host, port).db(name)
  # config.slaves = [
    # Mongo::Connection.new(host, port, :slave_ok => true).db(name),
    # Mongo::Connection.new(host, port, :slave_ok => true).db(name)
  # ]
end

Dir[File.join(MODELS, "*.rb")].sort.each {|file| require File.basename(file) }

Spec::Runner.configure do |config|
  config.mock_with :mocha
  config.after :suite do
    Mongoid.database.collections.each(&:drop)
  end
end
