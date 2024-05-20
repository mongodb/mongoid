# frozen_string_literal: true
# rubocop:todo all

require "mongoid/clients/factory"
require "mongoid/clients/validators"
require "mongoid/clients/storage_options"
require "mongoid/clients/options"
require "mongoid/clients/sessions"

module Mongoid

  # Mixin module included into Mongoid::Document which adds
  # database client connection functionality. Also contains
  # singleton class methods related to managing database clients.
  module Clients
    extend ActiveSupport::Concern
    include StorageOptions
    include Options
    include Sessions

    class << self

      # Clear all clients from the current thread.
      #
      # @example Clear all clients.
      #   Mongoid::Clients.clear
      #
      # @return [ Array ] The empty clients.
      def clear
        clients.clear
      end

      # Get the default client.
      #
      # @example Get the default client.
      #   Mongoid::Clients.default
      #
      # @return [ Mongo::Client ] The default client.
      def default
        with_name(:default)
      end

      # Disconnect all active clients.
      #
      # @example Disconnect all active clients.
      #   Mongoid::Clients.disconnect
      #
      # @return [ true ] True.
      def disconnect
        clients.each_value(&:close)
        true
      end

      # Reconnect all active clients.
      #
      # @example Reconnect all active clients.
      #   Mongoid::Clients.reconnect
      #
      # @return [ true ] True.
      def reconnect
        clients.each_value(&:reconnect)
        true
      end

      # Get a stored client with the provided name. If no client exists
      # with the given name, a new one will be created, stored, and
      # returned.
      #
      # @example Get a client with the name.
      #   Mongoid::Clients.with_name(:replica)
      #
      # @param [ String | Symbol ] name The name of the client.
      #
      # @return [ Mongo::Client ] The named client.
      def with_name(name)
        name_as_symbol = name.to_sym
        return clients[name_as_symbol] if clients[name_as_symbol]
        CREATE_LOCK.synchronize do
          if (key_vault_client = Mongoid.clients.dig(name_as_symbol, :options, :auto_encryption_options, :key_vault_client))
            clients[key_vault_client.to_sym] ||= Clients::Factory.create(key_vault_client)
          end
          clients[name_as_symbol] ||= Clients::Factory.create(name)
        end
      end

      # Store a client with the provided name.
      #
      # @example Set a client.
      #   Mongoid::Clients.set(:analytics, my_client)
      #
      # @param [ String | Symbol ] name The name of the client to set.
      # @param [ Mongo::Client ] client The client to set.
      #
      # @return [ Mongo::Client ] The set client.
      def set(name, client)
        clients[name.to_sym] = client
      end

      # Returns the stored clients indexed by name.
      #
      # @return [ Hash<Symbol, Mongo::Client> ] The index of clients.
      def clients
        @clients ||= {}
      end

      private

      CREATE_LOCK = Mutex.new
    end
  end
end
