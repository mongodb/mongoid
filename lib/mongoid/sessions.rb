# encoding: utf-8
require "mongoid/sessions/factory"
require "mongoid/sessions/validators"
require "mongoid/sessions/storage_options"
require "mongoid/sessions/thread_options"
require "mongoid/sessions/options"

module Mongoid
  module Sessions
    extend ActiveSupport::Concern
    extend Gem::Deprecate
    include StorageOptions
    include ThreadOptions
    include Options

    class << self

      # Clear all clients from the current thread.
      #
      # @example Clear all clients.
      #   Mongoid::Sessions.clear
      #
      # @return [ Array ] The empty clients.
      #
      # @since 3.0.0
      def clear
        Threaded.clients.clear
      end

      # Get the default client.
      #
      # @example Get the default client.
      #   Mongoid::Sessions.default
      #
      # @return [ Mongo::Client ] The default client.
      #
      # @since 3.0.0
      def default
        Threaded.clients[:default] ||= Sessions::Factory.default
      end

      # Disconnect all active clients.
      #
      # @example Disconnect all active clients.
      #   Mongoid::Sessions.disconnect
      #
      # @return [ true ] True.
      #
      # @since 3.1.0
      def disconnect
        Threaded.clients.values.each do |client|
          # client.close
        end
      end

      # Get a client with the provided name.
      #
      # @example Get a client with the name.
      #   Mongoid::Sessions.with_name(:replica)
      #
      # @param [ Symbol ] name The name of the client.
      #
      # @return [ Mongo::Client ] The named client.
      #
      # @since 3.0.0
      def with_name(name)
        Threaded.clients[name.to_sym] ||= Sessions::Factory.create(name)
      end

      def set(name, client)
        Threaded.clients[name.to_sym] = client
      end
    end

    # Get the collection for this model from the client. Will check for an
    # overridden collection name from the store_in macro or the collection
    # with a pluralized model name.
    #
    # @example Get the model's collection.
    #   Model.collection
    #
    # @return [ Mongo::Collection ] The collection.
    #
    # @since 3.0.0
    def collection
      mongo_client[collection_name]
    end

    def mongo_client
      super || self.class.mongo_client
    end
    alias :mongo_session :mongo_client
    deprecate :mongo_session, :mongo_client, 2015, 12

    def collection_name
      super || self.class.collection_name
    end

    module ClassMethods
      extend Gem::Deprecate

      # Get the client for this model. This is determined in the following order:
      #
      #   1. Any custom configuration provided by the 'store_in' macro.
      #   2. The 'default' client as provided in the mongoid.yml
      #
      # @example Get the client.
      #   Model.mongo_client
      #
      # @return [ Mongo::Client ] The default mongo client.
      #
      # @since 3.0.0
      def mongo_client
        name = client_name
        client = Sessions.with_name(name)
        client = client.use(database_name)
        client = self.persistence_options.blank? ? client : client.with(self.persistence_options)
        Sessions.set(name, client)
      end
      alias :mongo_session :mongo_client
      deprecate :mongo_session, :mongo_client, 2015, 12

      # Get the collection for this model from the session. Will check for an
      # overridden collection name from the store_in macro or the collection
      # with a pluralized model name.
      #
      # @example Get the model's collection.
      #   Model.collection
      #
      # @return [ Mongo::Collection ] The collection.
      #
      # @since 3.0.0
      def collection
        mongo_client[collection_name]
      end
    end
  end
end
