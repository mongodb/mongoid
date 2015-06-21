# encoding: utf-8

module Mongoid
  module Clients
    module Factory
      extend self

      # Create a new client given the named configuration. If no name is
      # provided, return a new client with the default configuration. If a
      # name is provided for which no configuration exists, an error will be
      # raised.
      #
      # @example Create the client.
      #   Factory.create(:secondary)
      #
      # @param [ String, Symbol ] name The named client configuration.
      #
      # @raise [ Errors::NoClientConfig ] If no config could be found.
      #
      # @return [ Mongo::Client ] The new client.
      #
      # @since 3.0.0
      def create(name = nil)
        return default unless name
        config = Mongoid.clients[name]
        raise Errors::NoClientConfig.new(name) unless config
        create_client(config)
      end

      # Get the default client.
      #
      # @example Get the default client.
      #   Factory.default
      #
      # @raise [ Errors::NoClientConfig ] If no default configuration is
      #   found.
      #
      # @return [ Mongo::Client ] The default client.
      #
      # @since 3.0.0
      def default
        create_client(Mongoid.clients[:default])
      end

      private

      # Create the client for the provided config.
      #
      # @api private
      #
      # @example Create the client.
      #   Factory.create_client(config)
      #
      # @param [ Hash ] configuration The client config.
      #
      # @return [ Mongo::Client ] The client.
      #
      # @since 3.0.0
      def create_client(configuration)
        raise Errors::NoClientsConfig.new unless configuration
        if configuration[:uri]
          Mongo::Client.new(configuration[:uri], options(configuration))
        else
          Mongo::Client.new(
            configuration[:hosts],
            options(configuration).merge(database: configuration[:database])
          )
        end
      end

      def options(configuration)
        config = configuration.dup
        options = config.delete(:options) || {}
        options.reject{ |k, v| k == :hosts }.to_hash.symbolize_keys!
      end
    end
  end
end
