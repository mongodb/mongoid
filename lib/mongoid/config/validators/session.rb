# encoding: utf-8
module Mongoid
  module Config
    module Validators

      # Validator for session specific configuration.
      module Session
        extend self

        # Validate the session configuration.
        #
        # @example Validate the session config.
        #   Session.validate({ default: { hosts: [ "localhost:27017" ] }})
        #
        # @param [ Hash ] sessions The sessions config.
        #
        # @since 3.0.0
        def validate(sessions)
          unless sessions.has_key?(:default)
            raise Errors::NoDefaultSession.new(sessions.keys)
          end
          sessions.each_pair do |name, config|
            validate_session_database(name, config)
            validate_session_hosts(name, config)
          end
        end

        private

        # Validate that the session config has database.
        #
        # @api private
        #
        # @example Validate the session has database.
        #   validator.validate_session_database(:default, {})
        #
        # @param [ String, Symbol ] name The config key.
        # @param [ Hash ] config The configuration.
        #
        # @since 3.0.0
        def validate_session_database(name, config)
          unless config.has_key?(:database)
            raise Errors::NoSessionDatabase.new(name, config)
          end
        end

        # Validate that the session config has hosts.
        #
        # @api private
        #
        # @example Validate the session has hosts.
        #   validator.validate_session_hosts(:default, {})
        #
        # @param [ String, Symbol ] name The config key.
        # @param [ Hash ] config The configuration.
        #
        # @since 3.0.0
        def validate_session_hosts(name, config)
          unless config.has_key?(:hosts)
            raise Errors::NoSessionHosts.new(name, config)
          end
        end
      end
    end
  end
end
