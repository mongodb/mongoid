require "rubygems"

gem "mongodb-mongo", "0.13"

require "mongo"
require "mongoloid/document"

module Mongoloid

  class NoConnectionError < RuntimeError
  end

  def self.connect_to(name)
    @@connection ||= XGen::Mongo::Connection.new
    @@database ||= @@connection.db(name)
  end

  def self.database
    raise NoConnectionError unless @@database
    @@database
  end

end
