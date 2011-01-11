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
      the slaves are not running locally.

      See the following configuration files for assistance:
        spec/config/mongod.conf
        spec/config/mongod.slave.one.conf
        spec/config/mongod.slave.two.conf
      ---------------------------------------------------------------------
      }
    end
  end
end
