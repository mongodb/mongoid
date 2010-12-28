# encoding: utf-8
module Support #:nodoc:
  module Slaves
    extend self

    def configured?
      begin
        slave_one_uri = "mongodb://mongoid:test@localhost:27018/mongoid_test"
        slave_two_uri = "mongodb://mongoid:test@localhost:27019/mongoid_test"
        Mongo::Connection.from_uri(slave_one_uri, :slave_ok => true)
        Mongo::Connection.from_uri(slave_two_uri, :slave_ok => true)
        true
      rescue Mongo::ConnectionFailure => e
        false
      end
    end

    def message
      %Q{
      ---------------------------------------------------------------------
      The Mongoid configuration specs require 2 slave databases to be
      running in order to properly be tested. Those specs are skipped when
      the slaves are not running locally. Here is a sample configuration
      for a slave database:

        dbpath = /usr/local/var/mongodb/slave
        port = 27018
        slave = true
        bind_ip = 127.0.0.1
        source = 127.0.0.1:27017
      ---------------------------------------------------------------------
      }
    end
  end
end
