# encoding: utf-8
module Support #:nodoc:
  module MongoHQ
    extend self

    def configured?
      begin
        user = ENV["MONGOHQ_USER_MONGOID"]
        password = ENV["MONGOHQ_PASSWORD_MONGOID"]
        mongohq_uri = "mongodb://#{user}:#{password}@flame.mongohq.com:27040/mongoid"
        Mongo::Connection.from_uri(mongohq_uri)
        true
      rescue Mongo::MongoArgumentError, Mongo::ConnectionFailure
        false
      end
    end

    def message
      %Q{
      ---------------------------------------------------------------------
      The Mongoid configuration specs require an internet connection to
      connect to the test mongohq database, or require the username and
      password set as environment variables. If you need the credentials
      and want these specs to run, please contact durran at gmail dot com.

        ENV["MONGOHQ_USER_MONGOID"]
        ENV["MONGOHQ_PASSWORD_MONGOID"]
      ---------------------------------------------------------------------
      }
    end
  end
end
