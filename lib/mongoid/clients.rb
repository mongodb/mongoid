# encoding: utf-8
require "mongoid/clients/factory"
require "mongoid/clients/validators"
require "mongoid/clients/storage_options"
require "mongoid/clients/options"

module Mongoid
  module Clients
    extend ActiveSupport::Concern
    include StorageOptions
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
  end
end
