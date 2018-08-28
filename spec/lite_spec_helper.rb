# frozen_string_literal: true

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require "mongoid"
require "rspec"

begin
  require 'byebug'
rescue LoadError
end

require 'support/spec_config'

RSpec.configure do |config|
  if SpecConfig.instance.ci?
    config.add_formatter(RSpec::Core::Formatters::JsonFormatter, File.join(File.dirname(__FILE__), '../tmp/rspec.json'))
  end
end
