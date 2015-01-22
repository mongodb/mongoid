# encoding: utf-8

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
        if configuration[:uri]
          Mongo::Client.new(configuration[:uri], options(configuration))
        else
          Mongo::Client.new(configuration[:hosts], options(configuration))
        end
      end

      def options(configuration)
        options = configuration[:options] || {}
        options.merge(configuration.reject{ |k, v| k == :hosts }).to_hash.symbolize_keys!
      end
    end
  end
end
