# encoding: utf-8
module Mongoid
  module Config
    module Validators

      # Validator for session specific configuration.
      module Session
        extend self

        STANDARD = [ :database, :hosts, :username, :password ]

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
            validate_session_uri(name, config)
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
          if no_database_or_uri?(config)
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
          if no_hosts_or_uri?(config)
            raise Errors::NoSessionHosts.new(name, config)
          end
        end

        # Validate that not both a uri and standard options are provided for a
        # single session.
        #
        # @api private
        #
        # @example Validate the uri and options.
        #   validator.validate_session_uri(:default, {})
        #
        # @param [ String, Symbol ] name The config key.
        # @param [ Hash ] config The configuration.
        #
        # @since 3.0.0
        def validate_session_uri(name, config)
          if both_uri_and_standard?(config)
            raise Errors::MixedSessionConfiguration.new(name, config)
          end
        end

        # Return true if the configuration has no database or uri option
        # defined.
        #
        # @api private
        #
        # @example Validate the options.
        #   validator.no_database_or_uri?(config)
        #
        # @param [ Hash ] config The configuration options.
        #
        # @return [ true, false ] If no database or uri is defined.
        #
        # @since 3.0.0
        def no_database_or_uri?(config)
          !config.has_key?(:database) && !config.has_key?(:uri)
        end

        # Return true if the configuration has no hosts or uri option
        # defined.
        #
        # @api private
        #
        # @example Validate the options.
        #   validator.no_hosts_or_uri?(config)
        #
        # @param [ Hash ] config The configuration options.
        #
        # @return [ true, false ] If no hosts or uri is defined.
        #
        # @since 3.0.0
        def no_hosts_or_uri?(config)
          !config.has_key?(:hosts) && !config.has_key?(:uri)
        end

        # Return true if the configuration has both standard options and a uri
        # defined.
        #
        # @api private
        #
        # @example Validate the options.
        #   validator.no_database_or_uri?(config)
        #
        # @param [ Hash ] config The configuration options.
        #
        # @return [ true, false ] If both standard and uri are defined.
        #
        # @since 3.0.0
        def both_uri_and_standard?(config)
          config.has_key?(:uri) && config.keys.any? do |key|
            STANDARD.include?(key.to_sym)
          end
        end
      end
    end
  end
end
