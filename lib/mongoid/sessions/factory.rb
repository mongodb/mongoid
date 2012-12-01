# encoding: utf-8
require "mongoid/sessions/mongo_uri"

module Mongoid
  module Sessions
    module Factory
      extend self

      # Create a new session given the named configuration. If no name is
      # provided, return a new session with the default configuration. If a
      # name is provided for which no configuration exists, an error will be
      # raised.
      #
      # @example Create the session.
      #   Factory.create(:secondary)
      #
      # @param [ String, Symbol ] name The named session configuration.
      #
      # @raise [ Errors::NoSessionConfig ] If no config could be found.
      #
      # @return [ Moped::Session ] The new session.
      #
      # @since 3.0.0
      def create(name = nil)
        return default unless name
        config = Mongoid.sessions[name]
        raise Errors::NoSessionConfig.new(name) unless config
        create_session(config)
      end

      # Get the default session.
      #
      # @example Get the default session.
      #   Factory.default
      #
      # @raise [ Errors::NoSessionConfig ] If no default configuration is
      #   found.
      #
      # @return [ Moped::Session ] The default session.
      #
      # @since 3.0.0
      def default
        create_session(Mongoid.sessions[:default])
      end

      private

      # Create the session for the provided config.
      #
      # @api private
      #
      # @example Create the session.
      #   Factory.create_session(config)
      #
      # @param [ Hash ] configuration The session config.
      #
      # @return [ Moped::Session ] The session.
      #
      # @since 3.0.0
      def create_session(configuration)
        raise Errors::NoSessionsConfig.new unless configuration
        config, options = parse(configuration)
        configuration.merge!(config) if configuration.delete(:uri)
        session = Moped::Session.new(config[:hosts], options)
        session.use(config[:database])
        if authenticated?(config)
          session.login(config[:username], config[:password])
        end
        session
      end

      # Are we authenticated with this session config?
      #
      # @api private
      #
      # @example Is this session authenticated?
      #   Factory.authenticated?(config)
      #
      # @param [ Hash ] config The session config.
      #
      # @return [ true, false ] If we are authenticated.
      #
      # @since 3.0.0
      def authenticated?(config)
        config.has_key?(:username) && config.has_key?(:password)
      end

      # Parse the configuration. If a uri is provided we need to extract the
      # elements of it, otherwise the options are left alone.
      #
      # @api private
      #
      # @example Parse the config.
      #   Factory.parse(config)
      #
      # @param [ Hash ] config The configuration.
      #
      # @return [ Array<Hash> ] The configuration, parsed.
      #
      # @since 3.0.0
      def parse(config)
        options = config[:options].try(:dup) || {}
        parsed = if config.has_key?(:uri)
          MongoUri.new(config[:uri]).to_hash
        else
          inject_ports(config)
        end
        [ parsed, options.symbolize_keys ]
      end

      # Will inject the default port of 27017 if not supplied.
      #
      # @example Inject default ports.
      #   factory.inject_ports(config)
      #
      # @param [ Hash ] config The session configuration.
      #
      # @return [ Hash ] The altered configuration.
      #
      # @since 3.1.0
      def inject_ports(config)
        config["hosts"] = config["hosts"].map do |host|
          host =~ /:/ ? host : "#{host}:27017"
        end
        config
      end
    end
  end
end
