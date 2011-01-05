# encoding: utf-8
module Support #:nodoc:
  module Authentication
    extend self

    def configured?
      begin
        master_uri = "mongodb://mongoid:test@localhost:27017/mongoid_test"
        Mongo::Connection.from_uri(master_uri)
        true
      rescue Mongo::AuthenticationError => e
        false
      end
    end

    def message
      %Q{
      ---------------------------------------------------------------------
      A user needs to be configured for authentication, otherwise some
      configuration specs will not get run. You may set it up from the
      mongo console:

        $ use mongoid_test;
        $ db.addUser("mongoid", "test");
      ---------------------------------------------------------------------
      }
    end
  end
end
