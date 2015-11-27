# encoding: utf-8
require "mongoid/clients/factory"
require "mongoid/clients/validators"
require "mongoid/clients/storage_options"
require "mongoid/clients/thread_options"
require "mongoid/clients/options"

module Mongoid
  module Clients
    extend ActiveSupport::Concern
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

    def collection_name
      super || self.class.collection_name
    end

    module ClassMethods

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
        return client_with_options if client_with_options
        client = Clients.with_name(client_name)
        opts = self.persistence_options ? self.persistence_options.dup : {}
        if defined?(Mongo::Client::VALID_OPTIONS)
          opts.reject! { |k, v| !Mongo::Client::VALID_OPTIONS.include?(k.to_sym) }
        end
        opts.merge!(database: database_name) unless client.database.name.to_sym == database_name.to_sym
        client.with(opts)
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
    end
  end
end
