$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
require 'rubygems'

gem "mocha", "0.9.8"

require "mocha"
require "mongoid"
require "spec"

Mongoid.connect_to("mongoid_test")

Spec::Runner.configure do |config|
  config.mock_with :mocha
  Mocha::Configuration.prevent(:stubbing_non_existent_method)
end
