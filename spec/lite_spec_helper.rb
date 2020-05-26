# frozen_string_literal: true
# encoding: utf-8

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

# Load byebug before mongoid, to place breakpoints in the lib methods.
# But SpecConfig needs the driver code - require the driver here.
require "mongo"

# MRI 2.5 and JRuby 9.2 change visibility of Object#pp when 'pp' is required,
# which happens when RSpec reports anything. This creates an issue for tests
# that verify method forwarding. Work around by proactively loading 'pp'.
# https://github.com/jruby/jruby/issues/5599
require 'pp'

require 'support/spec_config'
require 'support/lite_constraints'

unless SpecConfig.instance.ci?
  begin
    require 'byebug'
  rescue LoadError
    # jruby - try pry
    begin
      require 'pry'
    # jruby likes to raise random error classes, in this case
    # NameError in addition to LoadError
    rescue Exception
    end
  end
end

require 'mongoid'

if SpecConfig.instance.mri?
  require 'timeout_interrupt'
else
  require 'timeout'
  TimeoutInterrupt = Timeout
end

RSpec.configure do |config|
  config.expect_with(:rspec) do |c|
    c.syntax = [:should, :expect]
  end

  if SpecConfig.instance.ci?
    config.add_formatter(RSpec::Core::Formatters::JsonFormatter, File.join(File.dirname(__FILE__), '../tmp/rspec.json'))
  end

  if SpecConfig.instance.ci?
    timeout = if SpecConfig.instance.app_tests?
      # Allow 5 minutes per test for the app tests, since they install
      # gems for Rails applications which can take a long time.
      300
    else
      # Allow a max of 30 seconds per test.
      # Tests should take under 10 seconds ideally but it seems
      # we have some that run for more than 10 seconds in CI.
      30
    end
    config.around(:each) do |example|
      TimeoutInterrupt.timeout(timeout) do
        example.run
      end
    end
  end

  config.extend(LiteConstraints)
end

# require all shared examples
Dir['./spec/support/shared/*.rb'].sort.each { |file| require file }
