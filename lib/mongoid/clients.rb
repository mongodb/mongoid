# frozen_string_literal: true

require "mongoid/clients/factory"
require "mongoid/clients/validators"
require "mongoid/clients/storage_options"
require "mongoid/clients/options"
require "mongoid/clients/sessions"

module Mongoid
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
        clients.values.each do |client|
          client.close
        end
      end

      # Get a client with the provided name.
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
          clients[name_as_symbol] ||= Clients::Factory.create(name)
        end
      end

      def set(name, client)
        clients[name.to_sym] = client
      end

      def clients
        @clients ||= {}
      end

      private

      CREATE_LOCK = Mutex.new
    end
  end
end
