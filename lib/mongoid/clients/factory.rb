# frozen_string_literal: true

module Mongoid
  module Clients
    module Factory
      extend self
      extend Loggable

      # Create a new client given the named configuration. If no name is
      # provided, return a new client with the default configuration. If a
      # name is provided for which no configuration exists, an error will be
      # raised.
      #
      # @example Create the client.
      #   Factory.create(:analytics)
      #
      # @param [ String | Symbol ] name The named client configuration.
      #
      # @raise [ Errors::NoClientConfig ] If no config could be found.
      #
      # @return [ Mongo::Client ] The new client.
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
      def create_client(configuration)
        raise Errors::NoClientsConfig.new unless configuration
        config = configuration.dup
        uri = config.delete(:uri)
        database = config.delete(:database)
        hosts = config.delete(:hosts)
        opts = config.delete(:options) || {}
        unless config.empty?
          default_logger.warn("Unknown config options detected: #{config}.")
        end
        if uri
          Mongo::Client.new(uri, options(opts))
        else
          Mongo::Client.new(
            hosts,
            options(opts).merge(database: database)
          )
        end
      end

      MONGOID_WRAPPING_LIBRARY = {
        name: 'Mongoid',
        version: VERSION,
      }.freeze

      def driver_version
        Mongo::VERSION.split('.')[0...2].map(&:to_i)
      end

      # Prepare options for Mongo::Client based on Mongoid client configuration.
      #
      # @param [ Hash ] opts Parameters from options section of Mongoid client configuration.
      # @return [ Hash ] Options that should be passed to Mongo::Client constructor.
      #
      # @api private
      def options(opts)
        options = opts.dup
        options[:platform] = PLATFORM_DETAILS
        options[:app_name] = Mongoid::Config.app_name if Mongoid::Config.app_name
        if (driver_version <=> [2, 13]) >= 0
          wrap_lib = if options[:wrapping_libraries]
            [MONGOID_WRAPPING_LIBRARY] + options[:wrapping_libraries]
          else
            [MONGOID_WRAPPING_LIBRARY]
          end
          options[:wrapping_libraries] = wrap_lib
        end
        options.reject{ |k, _v| k == :hosts }.to_hash.symbolize_keys!
      end
    end
  end
end
