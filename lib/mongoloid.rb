require "rubygems"

gem "activesupport"
gem "mongodb-mongo", "0.14"

require "activesupport"
require "mongo"
require "mongoloid/association"
require "mongoloid/document"
require "mongoloid/document_factory"
require "mongoloid/paginator"

module Mongoloid

  class NoConnectionError < RuntimeError
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
