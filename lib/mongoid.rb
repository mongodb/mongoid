# frozen_string_literal: true
# encoding: utf-8

require "support/ruby_version"

require "forwardable"
require "time"
require "set"

require "active_support"
require "active_support/core_ext"
require "active_support/json"
require "active_support/inflector"
require "active_support/time_with_zone"
require "active_model"

require "mongo"
require 'mongo/active_support'

require "mongoid/version"
require "mongoid/config"
require "mongoid/persistence_context"
require "mongoid/loggable"
require "mongoid/clients"
require "mongoid/document"
require "mongoid/tasks/database"
require "mongoid/query_cache"

# If we are using Rails then we will include the Mongoid railtie. This has all
# the nifty initializers that Mongoid needs.
if defined?(Rails)
  require "mongoid/railtie"
end

# add english load path by default
I18n.load_path << File.join(File.dirname(__FILE__), "config", "locales", "en.yml")

module Mongoid
  extend Forwardable
  extend Loggable
  extend self

  # A string added to the platform details of Ruby driver client handshake documents.
  #
  # @since 6.1.0
  PLATFORM_DETAILS = "mongoid-#{VERSION}".freeze

  # The minimum MongoDB version supported.
  MONGODB_VERSION = "2.6.0"

  # Sets the Mongoid configuration options. Best used by passing a block.
  #
  # @example Set up configuration options.
  #   Mongoid.configure do |config|
  #     config.connect_to("mongoid_test")
  #
  #     config.clients.default = {
  #       hosts: ["localhost:27017"],
  #       database: "mongoid_test",
  #     }
  #   end
  #
  # @return [ Config ] The configuration object.
  #
  # @since 1.0.0
  def configure
    block_given? ? yield(Config) : Config
  end

  # Convenience method for getting the default client.
  #
  # @example Get the default client.
  #   Mongoid.default_client
  #
  # @return [ Mongo::Client ] The default client.
  #
  # @since 5.0.0
  def default_client
    Clients.default
  end

  # Disconnect all active clients.
  #
  # @example Disconnect all active clients.
  #   Mongoid.disconnect_clients
  #
  # @return [ true ] True.
  #
  # @since 5.0.0
  def disconnect_clients
    Clients.disconnect
  end

  # Convenience method for getting a named client.
  #
  # @example Get a named client.
  #   Mongoid.client(:default)
  #
  # @return [ Mongo::Client ] The named client.
  #
  # @since 5.0.0
  def client(name)
    Clients.with_name(name)
  end

  # Take all the public instance methods from the Config singleton and allow
  # them to be accessed through the Mongoid module directly.
  #
  # @example Delegate the configuration methods.
  #   Mongoid.database = Mongo::Connection.new.db("test")
  #
  # @since 1.0.0
  def_delegators Config, *(Config.public_instance_methods(false) - [ :logger=, :logger ])
end
