# frozen_string_literal: true

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require "mongoid"
require "rspec"

begin
  require 'byebug'
rescue LoadError
end

RSpec.configure do |config|
  if SpecConfig.instance.ci?
    require 'rspec_junit_formatter'
    config.add_formatter('RSpecJUnitFormatter', File.join(File.dirname(__FILE__), '../tmp/rspec.xml'))
  end
end
