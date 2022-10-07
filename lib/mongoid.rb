# frozen_string_literal: true

require "forwardable"
require "time"
require "set"
require "ruby2_keywords"

require "active_support"
require "active_support/core_ext"
require "active_support/json"
require "active_support/inflector"
require "active_support/time_with_zone"
require "active_model"

require 'concurrent-ruby'

require "mongo"
require "mongo/active_support"

require "mongoid/version"
require "mongoid/deprecable"
require "mongoid/config"
require "mongoid/persistence_context"
require "mongoid/loggable"
require "mongoid/clients"
require "mongoid/document"
require "mongoid/tasks/database"
require "mongoid/query_cache"
require "mongoid/warnings"
require "mongoid/utils"

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
  # @example Using a block without an argument. Use `config` inside
  #   the block to perform variable assignment.
  #
  #   Mongoid.configure do
  #     connect_to("mongoid_test")
  #
  #     config.preload_models = true
  #
  # @return [ Config ] The configuration object.
  def configure(&block)
    return Config unless block_given?

    block.arity == 0 ? Config.instance_exec(&block) : yield(Config)
  end

  # Convenience method for getting the default client.
  #
  # @example Get the default client.
  #   Mongoid.default_client
  #
  # @return [ Mongo::Client ] The default client.
  def default_client
    Clients.default
  end

  # Disconnect all active clients.
  #
  # @example Disconnect all active clients.
  #   Mongoid.disconnect_clients
  #
  # @return [ true ] True.
  def disconnect_clients
    Clients.disconnect
  end

  # Convenience method for getting a named client.
  #
  # @example Get a named client.
  #   Mongoid.client(:default)
  #
  # @return [ Mongo::Client ] The named client.
  def client(name)
    Clients.with_name(name)
  end

  # Take all the public instance methods from the Config singleton and allow
  # them to be accessed through the Mongoid module directly.
  #
  # @example Delegate the configuration methods.
  #   Mongoid.database = Mongo::Connection.new.db("test")
  def_delegators Config, *(Config.public_instance_methods(false) - [ :logger=, :logger ])


  # Module used to prepend the discriminator key assignment function to change
  # the value assigned to the discriminator key to a string.
  #
  # @api private
  module GlobalDiscriminatorKeyAssignment
    # This class is used for obtaining the method definition location for
    # Mongoid methods.
    class InvalidFieldHost
      include Mongoid::Document
    end

    def discriminator_key=(value)
      Mongoid::Fields::Validators::Macro.validate_field_name(InvalidFieldHost, value)
      value = value.to_s
      super
    end
  end

  class << self
    prepend GlobalDiscriminatorKeyAssignment
  end
end
