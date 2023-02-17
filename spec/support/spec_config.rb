# frozen_string_literal: true

require 'singleton'

class SpecConfig
  include Singleton

  DEFAULT_MONGODB_URI = "mongodb://127.0.0.1:27017"

  def initialize
    if ENV['MONGODB_URI']
      @uri_str = ENV['MONGODB_URI']
    else
      STDERR.puts "Environment variable 'MONGODB_URI' is not set, so the default url will be used."
      STDERR.puts "This may lead to unexpected test failures because service discovery will raise unexpected warnings."
      STDERR.puts "Please consider providing the correct uri via MONGODB_URI environment variable."
      @uri_str = DEFAULT_MONGODB_URI
    end
    
    @uri = Mongo::URI.new(@uri_str)
  end

  attr_reader :uri_str
  attr_reader :uri

  def addresses
    @uri.servers
  end

  def mri?
    !jruby?
  end

  def jruby?
    RUBY_PLATFORM =~ /\bjava\b/
  end

  def windows?
    ENV['OS'] == 'Windows_NT' && !RUBY_PLATFORM.match?(/cygwin/)
  end

  def platform
    RUBY_PLATFORM
  end

  def client_debug?
    %w(1 true yes).include?(ENV['CLIENT_DEBUG']&.downcase)
  end

  def app_tests?
    %w(1 true yes).include?(ENV['APP_TESTS']&.downcase)
  end

  def ci?
    !!ENV['CI']
  end

  def rails_version
    v = ENV['RAILS']
    if v == ''
      v = nil
    end
    v || '6.1'
  end
end
