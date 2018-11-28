# frozen_string_literal: true

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require "mongoid"
require "rspec"

require 'support/spec_config'

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

if SpecConfig.instance.mri?
  require 'timeout_interrupt'
else
  require 'timeout'
  TimeoutInterrupt = Timeout
end

RSpec.configure do |config|
  if SpecConfig.instance.ci?
    config.add_formatter(RSpec::Core::Formatters::JsonFormatter, File.join(File.dirname(__FILE__), '../tmp/rspec.json'))
  end

  if SpecConfig.instance.ci?
    # Allow a max of 30 seconds per test.
    # Tests should take under 10 seconds ideally but it seems
    # we have some that run for more than 10 seconds in CI.
    config.around(:each) do |example|
      TimeoutInterrupt.timeout(30) do
        example.run
      end
    end
  end
end

# require all shared examples
Dir['./spec/support/shared/*.rb'].sort.each { |file| require file }
