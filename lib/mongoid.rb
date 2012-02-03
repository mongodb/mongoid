# encoding: utf-8

# Copyright (c) 2009 - 2011 Durran Jordan and friends.
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
require "delegate"
require "time"
require "set"

require "active_support/core_ext"
require 'active_support/json'
require "active_support/inflector"
require "active_support/time_with_zone"
require "active_model"

require "origin"
require "moped"
BSON = Moped::BSON

require "mongoid/extensions"
require "mongoid/errors"
require "mongoid/safety"
require "mongoid/threaded"
require "mongoid/relations"
require "mongoid/atomic"
require "mongoid/attributes"
require "mongoid/callbacks"
require "mongoid/config"
require "mongoid/contextual"
require "mongoid/copyable"
require "mongoid/criteria"
require "mongoid/dirty"
require "mongoid/factory"
require "mongoid/fields"
require "mongoid/finders"
require "mongoid/hierarchy"
require "mongoid/identity_map"
require "mongoid/indexes"
require "mongoid/inspection"
require "mongoid/javascript"
require "mongoid/json"
require "mongoid/logger"
require "mongoid/matchers"
require "mongoid/multi_parameter_attributes"
require "mongoid/multi_database"
require "mongoid/nested_attributes"
require "mongoid/observer"
require "mongoid/persistence"
require "mongoid/reloading"
require "mongoid/scoping"
require "mongoid/serialization"
require "mongoid/sessions"
require "mongoid/sharding"
require "mongoid/state"
require "mongoid/timestamps"
require "mongoid/unit_of_work"
require "mongoid/validations"
require "mongoid/version"
require "mongoid/versioning"
require "mongoid/components"
require "mongoid/paranoia"
require "mongoid/document"

# If we are using Rails then we will include the Mongoid railtie. This has all
# the nifty initializers that Mongoid needs.
if defined?(Rails)
  require "mongoid/railtie"
end

# If we are using any Rack based application then we need the Mongoid rack
# middleware to ensure our app is running properly.
if defined?(Rack)
  require "rack/mongoid"
end

# add english load path by default
I18n.load_path << File.join(File.dirname(__FILE__), "config", "locales", "en.yml")

module Mongoid #:nodoc
  extend UnitOfWork
  extend self

  MONGODB_VERSION = "2.0.0"

  # Sets the Mongoid configuration options. Best used by passing a block.
  #
  # @example Set up configuration options.
  #   Mongoid.configure do |config|
  #     config.allow_dynamic_fields = false
  #     config.use(name: "mongoid_test", host: "localhost", port: 27017)
  #   end
  #
  # @return [ Config ] The configuration obejct.
  #
  # @since 1.0.0
  def configure
    block_given? ? yield(Config) : Config
  end

  def default_session
    Sessions.default
  end

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
  delegate(*(Config.public_instance_methods(false) +
    ActiveModel::Observing::ClassMethods.public_instance_methods(false) <<
    { to: Config }))
end
