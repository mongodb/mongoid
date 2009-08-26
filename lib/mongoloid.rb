require "rubygems"

gem "mongodb-mongo", "0.13"

require "mongo"
require "mongoloid/document"

module Mongoloid
  
  def self.connection
    @@connection ||= XGen::Mongo::Driver::Mongo.new
  end
  
  def self.connection=(conn)
    @@connection = conn
  end
  
end