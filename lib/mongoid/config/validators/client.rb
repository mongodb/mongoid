# frozen_string_literal: true

module Mongoid
  module Config
    module Validators
      # Validator for client specific configuration.
      module Client
        extend self

        # Standard configuration options.
        STANDARD = %i[database hosts username password].freeze

        # Validate the client configuration.
        #
        # @example Validate the client config.
        #   Client.validate({ default: { hosts: [ "localhost:27017" ] }})
        #
        # @param [ Hash ] clients The clients config.
        def validate(clients)
          raise Errors::NoDefaultClient.new(clients.keys) unless clients.has_key?(:default)

          clients.each_pair do |name, config|
            validate_client_database(name, config)
            validate_client_hosts(name, config)
            validate_client_uri(name, config)
          end
        end

        private

        # Validate that the client config has database.
        #
        # @api private
        #
        # @example Validate the client has database.
        #   validator.validate_client_database(:default, {})
        #
        # @param [ String | Symbol ] name The config key.
        # @param [ Hash ] config The configuration.
        def validate_client_database(name, config)
          return unless no_database_or_uri?(config)

          raise Errors::NoClientDatabase.new(name, config)
        end

        # Validate that the client config has hosts.
        #
        # @api private
        #
        # @example Validate the client has hosts.
        #   validator.validate_client_hosts(:default, {})
        #
        # @param [ String | Symbol ] name The config key.
        # @param [ Hash ] config The configuration.
        def validate_client_hosts(name, config)
          return unless no_hosts_or_uri?(config)

          raise Errors::NoClientHosts.new(name, config)
        end

        # Validate that not both a uri and standard options are provided for a
        # single client.
        #
        # @api private
        #
        # @example Validate the uri and options.
        #   validator.validate_client_uri(:default, {})
        #
        # @param [ String | Symbol ] name The config key.
        # @param [ Hash ] config The configuration.
        def validate_client_uri(name, config)
          return unless both_uri_and_standard?(config)

          raise Errors::MixedClientConfiguration.new(name, config)
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
        # @return [ true | false ] If no database or uri is defined.
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
        # @return [ true | false ] If no hosts or uri is defined.
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
        # @return [ true | false ] If both standard and uri are defined.
        def both_uri_and_standard?(config)
          config.has_key?(:uri) && config.keys.any? do |key|
            STANDARD.include?(key.to_sym)
          end
        end
      end
    end
  end
end
