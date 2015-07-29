# encoding: utf-8
require "mongoid/clients/factory"
require "mongoid/clients/validators"
require "mongoid/clients/storage_options"
require "mongoid/clients/thread_options"
require "mongoid/clients/options"

module Mongoid
  module Clients
    extend ActiveSupport::Concern
    extend Gem::Deprecate
    include StorageOptions
    include ThreadOptions
    include Options

    class << self

      # Clear all clients from the current thread.
      #
      # @example Clear all clients.
      #   Mongoid::Clients.clear
      #
      # @return [ Array ] The empty clients.
      #
      # @since 3.0.0
      def clear
        clients.clear
      end

      # Get the default client.
      #
      # @example Get the default client.
      #   Mongoid::Clients.default
      #
      # @return [ Mongo::Client ] The default client.
      #
      # @since 3.0.0
      def default
        clients[:default] ||= Clients::Factory.default
      end

      # Disconnect all active clients.
      #
      # @example Disconnect all active clients.
      #   Mongoid::Clients.disconnect
      #
      # @return [ true ] True.
      #
      # @since 3.1.0
      def disconnect
        clients.values.each do |client|
          client.close
        end
      end

      # Get a client with the provided name.
      #
      # @example Get a client with the name.
      #   Mongoid::Clients.with_name(:replica)
      #
      # @param [ Symbol ] name The name of the client.
      #
      # @return [ Mongo::Client ] The named client.
      #
      # @since 3.0.0
      def with_name(name)
        clients[name.to_sym] ||= Clients::Factory.create(name)
      end

      def set(name, client)
        clients[name.to_sym] = client
      end

      def clients
        @clients ||= {}
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
        client = Clients.with_name(name)
        client = client.use(database_name)
        client.with(self.persistence_options)
      end
      alias :mongo_session :mongo_client
      deprecate :mongo_session, :mongo_client, 2015, 12

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
    end
  end
end
