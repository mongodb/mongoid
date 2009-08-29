$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
require 'rubygems'

gem "mocha", "0.9.7"

require "mocha"
require "mongoloid"
require "spec"

Mongoloid.connect_to("mongoloid_test")