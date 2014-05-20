# encoding: utf-8
require "support/ruby_version"

require "delegate"
require "time"
require "set"

require "active_support"
require "active_support/core_ext"
require "active_support/json"
require "active_support/inflector"
require "active_support/time_with_zone"
require "active_model"

require "origin"
require "moped"

require "mongoid/version"
require "mongoid/config"
require "mongoid/loggable"
require "mongoid/sessions"
require "mongoid/document"
require "mongoid/log_subscriber"
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
  extend Loggable
  extend self

  MONGODB_VERSION = "2.2.0"

  # Sets the Mongoid configuration options. Best used by passing a block.
  #
  # @example Set up configuration options.
  #   Mongoid.configure do |config|
  #     config.connect_to("mongoid_test")
  #   end
  #
  # @return [ Config ] The configuration object.
  #
  # @since 1.0.0
  def configure
    block_given? ? yield(Config) : Config
  end

  # Convenience method for getting the default session.
  #
  # @example Get the default session.
  #   Mongoid.default_session
  #
  # @return [ Moped::Session ] The default session.
  #
  # @since 3.0.0
  def default_session
    Sessions.default
  end

  # Disconnect all active sessions.
  #
  # @example Disconnect all active sessions.
  #   Mongoid.disconnect_sessions
  #
  # @return [ true ] True.
  #
  # @since 3.1.0
  def disconnect_sessions
    Sessions.disconnect
  end

  # Convenience method for getting a named session.
  #
  # @example Get a named session.
  #   Mongoid.session(:default)
  #
  # @return [ Moped::Session ] The named session.
  #
  # @since 3.0.0
  def session(name)
    Sessions.with_name(name)
  end

  # Take all the public instance methods from the Config singleton and allow
  # them to be accessed through the Mongoid module directly.
  #
  # @example Delegate the configuration methods.
  #   Mongoid.database = Mongo::Connection.new.db("test")
  #
  # @since 1.0.0
  delegate(*(Config.public_instance_methods(false) - [ :logger=, :logger ] << { to: Config }))
end
