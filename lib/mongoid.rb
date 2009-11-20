# Copyright (c) 2009 Durran Jordan
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
require "rubygems"

gem "activesupport", "2.3.4"
gem "mongo", "0.17"
gem "mongo_ext", "0.17"
gem "durran-validatable", "1.8.2"
gem "leshill-will_paginate", "2.3.11"

require "delegate"
require "observer"
require "time"
require "validatable"
require "active_support/callbacks"
require "active_support/core_ext"
require "active_support/time_with_zone"
require "will_paginate/collection"
require "mongo"
require "mongoid/associations"
require "mongoid/associations/options"
require "mongoid/attributes"
require "mongoid/commands"
require "mongoid/criteria"
require "mongoid/extensions"
require "mongoid/field"
require "mongoid/finders"
require "mongoid/timestamps"
require "mongoid/versioning"
require "mongoid/document"

module Mongoid

  # Raised when the database connection has not been set up.
  class NoConnectionError < RuntimeError; end

  # Raised when an association is defined on the class, but the
  # attribute in the hash is not an Array or Hash, or when
  # checking equality on objects of different types.
  class TypeMismatchError < RuntimeError; end

  # Raised when a persisence method ending in ! fails validation.
  class ValidationsError < RuntimeError; end

  # A common case of errors is to instantiate a child document without a
  # reference to a parent, which will result in trying to save on a nil
  # collection. This error is raised to help debug the issue.
  class MissingParentError < RuntimeError
    def initialize(doc)
      @document = doc
    end
    def message
      "Attempted to save embedded document #{@document.class.name}, but there was no associated parent"
    end
  end

  # Connect to the database name supplied. This should be run
  # for initial setup, potentially in a rails initializer.
  def self.connect_to(name)
    @@connection ||= Mongo::Connection.new
    @@database ||= @@connection.db(name)
  end

  # Get the MongoDB database. If initialization via Mongoid.connect_to()
  # has not happened, an exception will occur.
  def self.database
    raise NoConnectionError unless @@database
    @@database
  end

end
