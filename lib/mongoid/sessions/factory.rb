# encoding: utf-8
module Mongoid #:nodoc:
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
      # @param [ Hash ] config The session config.
      #
      # @return [ Moped::Session ] The session.
      #
      # @since 3.0.0
      def create_session(config)
        options = (config[:options] || {}).dup
        Moped::Session.new(config[:hosts], options).tap do |session|
          session.use(config[:database])
          if authenticated?(config)
            session.login(config[:username], config[:password])
          end
        end
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
    end
  end
end
