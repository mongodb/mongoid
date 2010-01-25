$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

MODELS = File.join(File.dirname(__FILE__), "models")
$LOAD_PATH.unshift(MODELS)

require 'rubygems'

gem "mocha", ">= 0.9.8"

require "mocha"
require "mongoid"
require "spec"

connection = Mongo::Connection.new

Mongoid.config do |config|
  config.database = connection.db("mongoid_test")
end

Dir[File.join(MODELS, "*.rb")].each {|file| require File.basename(file) }

Spec::Runner.configure do |config|
  config.mock_with :mocha
  config.after :suite do
    Mongoid.database.collections.each(&:drop)
  end
end