# encoding: utf-8
module Support #:nodoc:
  module Multi
    extend self

    def configured?
      begin
        master_uri = "mongodb://localhost:27020"
        slave_one_uri = "mongodb://localhost:27021"
        slave_two_uri = "mongodb://localhost:27022"
        Mongo::Connection.from_uri(master_uri)
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
      The Mongoid configuration specs require a secondary master with 2
      secondary slave databases to be running in order to properly be
      tested. For multi-database configurations. Those specs are skipped
      when those 3 databases are not running locally.

      See the following configuration files for assistance:
        spec/config/mongod.alt.conf
        spec/config/mongod.alt.slave.one.conf
        spec/config/mongod.alt.slave.two.conf
      ---------------------------------------------------------------------
      }
    end
  end
end
