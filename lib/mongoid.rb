# encoding: utf-8
# Copyright (c) 2009, 2010 Durran Jordan
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
require "singleton"
require "time"
require "ostruct"
require "active_support/core_ext"
require 'active_support/json'
require "active_support/inflector"
require "active_support/time_with_zone"
require "active_model"
require "active_model/callbacks"
require "active_model/conversion"
require "active_model/errors"
require "active_model/mass_assignment_security"
require "active_model/naming"
require "active_model/serialization"
require "active_model/translation"
require "active_model/validator"
require "active_model/validations"
require "will_paginate/collection"
require "mongo"
require "mongoid/errors"
require "mongoid/extensions"
require "mongoid/safe"
require "mongoid/associations"
require "mongoid/atomicity"
require "mongoid/attributes"
require "mongoid/callbacks"
require "mongoid/collection"
require "mongoid/collections"
require "mongoid/config"
require "mongoid/contexts"
require "mongoid/criteria"
require "mongoid/cursor"
require "mongoid/deprecation"
require "mongoid/dirty"
require "mongoid/extras"
require "mongoid/factory"
require "mongoid/field"
require "mongoid/fields"
require "mongoid/finders"
require "mongoid/hierarchy"
require "mongoid/identity"
require "mongoid/indexes"
require "mongoid/javascript"
require "mongoid/json"
require "mongoid/keys"
require "mongoid/logger"
require "mongoid/matchers"
require "mongoid/memoization"
require "mongoid/modifiers"
require "mongoid/multi_parameter_attributes"
require "mongoid/named_scope"
require "mongoid/paths"
require "mongoid/persistence"
require "mongoid/safety"
require "mongoid/scope"
require "mongoid/state"
require "mongoid/timestamps"
require "mongoid/validations"
require "mongoid/versioning"
require "mongoid/components"
require "mongoid/paranoia"
require "mongoid/document"

# add railtie
if defined?(Rails)
  require "mongoid/railtie"
end

# add english load path by default
I18n.load_path << File.join(File.dirname(__FILE__), "config", "locales", "en.yml")

module Mongoid #:nodoc

  MONGODB_VERSION = "1.6.0"

  class << self

    # Sets the Mongoid configuration options. Best used by passing a block.
    #
    # Example:
    #
    #   Mongoid.configure do |config|
    #     name = "mongoid_test"
    #     host = "localhost"
    #     config.allow_dynamic_fields = false
    #     config.master = Mongo::Connection.new.db(name)
    #     config.slaves = [
    #       Mongo::Connection.new(host, 27018, :slave_ok => true).db(name),
    #       Mongo::Connection.new(host, 27019, :slave_ok => true).db(name)
    #     ]
    #   end
    #
    # Returns:
    #
    # The Mongoid +Config+ singleton instance.
    def configure
      config = Mongoid::Config.instance
      block_given? ? yield(config) : config
    end

    # Easy convenience method for generating an alert from the
    # deprecation module.
    #
    # Example:
    #
    # <tt>Mongoid.deprecate("Method no longer used")</tt>
    def deprecate(message)
      Mongoid::Deprecation.instance.alert(message)
    end

    alias :config :configure
  end

  # Take all the public instance methods from the Config singleton and allow
  # them to be accessed through the Mongoid module directly.
  #
  # Example:
  #
  # <tt>Mongoid.database = Mongo::Connection.new.db("test")</tt>
  Mongoid::Config.public_instance_methods(false).each do |name|
    (class << self; self; end).class_eval <<-EOT
      def #{name}(*args)
        configure.send("#{name}", *args)
      end
    EOT
  end
end
