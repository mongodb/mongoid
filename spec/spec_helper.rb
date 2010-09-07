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
  host = "localhost"
  config.master = Mongo::Connection.new.db(name)
  config.logger = nil
  # config.slaves = [
    # Mongo::Connection.new(host, 27018, :slave_ok => true).db(name)
  # ]
end

Dir[ File.join(MODELS, "*.rb") ].sort.each { |file| require File.basename(file) }

Rspec.configure do |config|
  config.mock_with :mocha
  config.after :suite do
    Mongoid.master.collections.select {|c| c.name !~ /system/ }.each(&:drop)
  end
end
