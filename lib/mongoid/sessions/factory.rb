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
        Moped::Session.new(config[:hosts], config[:options] || {})
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
        config = Mongoid.sessions[:default] || { hosts: [ "localhost:27017" ] }
        Moped::Session.new(config[:hosts], config[:options] || {})
      end
    end
  end
end
