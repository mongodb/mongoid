# encoding: utf-8
module Support #:nodoc:
  module Multi
    extend self

    def configured?
      begin
        master_uri = "mongodb://localhost:27020"
        Mongo::Connection.from_uri(master_uri)
        true
      rescue Mongo::ConnectionFailure => e
        false
      end
    end

    def message
      %Q{
      ---------------------------------------------------------------------
      The Mongoid configuration specs require a secondary master in order
      to properly be tested. For multi-database configurations.
      Those specs are skipped when those 3 databases are not running locally.

      See the following configuration files for assistance:
        spec/config/mongod.alt.conf
      ---------------------------------------------------------------------
      }
    end
  end
end
