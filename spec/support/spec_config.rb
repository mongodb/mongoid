# frozen_string_literal: true
# encoding: utf-8

require 'singleton'

class SpecConfig
  include Singleton

  def initialize
    if ENV['MONGODB_URI']
      @uri_str = ENV['MONGODB_URI']
      @uri = Mongo::URI.new(@uri_str)
    end
  end

  attr_reader :uri_str
  attr_reader :uri

  def addresses
    if @uri
      @uri.servers
    else
      ['127.0.0.1']
    end
  end

  def mri?
    !jruby?
  end

  def jruby?
    RUBY_PLATFORM =~ /\bjava\b/
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
end
