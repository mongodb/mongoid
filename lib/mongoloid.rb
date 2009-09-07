require "rubygems"

gem "activesupport"
gem "mongodb-mongo", "0.14"

require "activesupport"
require "delegate"
require "mongo"
require "mongoloid/associations/association_factory"
require "mongoloid/associations/belongs_to_association"
require "mongoloid/associations/has_many_association"
require "mongoloid/associations/has_one_association"
require "mongoloid/document"
require "mongoloid/paginator"

module Mongoloid

  # Thrown when the database connection has not been set up.
  class NoConnectionError < RuntimeError
  end

  # Thrown when :document_class is not provided in the attributes
  # hash when creating a new Document
  class ClassNotProvidedError < RuntimeError
  end

  # Thrown when an association is defined on the class, but the 
  # attribute in the hash is not an Array or Hash.
  class TypeMismatchError < RuntimeError
  end

  # Thrown when an association is defined that is not valid. Must
  # be belongs_to, has_many, has_one
  class InvalidAssociationError < RuntimeError
  end

  # Connect to the database name supplied. This should be run
  # for initial setup, potentially in a rails initializer.
  def self.connect_to(name)
    @@connection ||= XGen::Mongo::Connection.new
    @@database ||= @@connection.db(name)
  end

  # Get the MongoDB database. If initialization via Mongoloid.connect_to()
  # has not happened, an exception will occur.
  def self.database
    raise NoConnectionError unless @@database
    @@database
  end

end
