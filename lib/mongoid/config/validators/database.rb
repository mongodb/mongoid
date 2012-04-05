# encoding: utf-8
module Mongoid
  module Config
    module Validators

      # Validator for database specific configuration.
      module Database
        extend self

        # Validate the database configuration.
        #
        # @example Validate the database config.
        #   Database.validate({ default: { name: "test" }})
        #
        # @param [ Hash ] dbs The databases config.
        #
        # @since 3.0.0
        def validate(dbs)
          unless dbs.has_key?(:default)
            raise Errors::NoDefaultDatabase.new(dbs.keys)
          end
          dbs.each_pair do |name, config|
            validate_database_name(name, config)
            validate_database_session(name, config)
          end
        end

        private

        # Validate that the database config has a name.
        #
        # @api private
        #
        # @example Validate the database has a name.
        #   validator.validate_database_name(:default, {})
        #
        # @param [ String, Symbol ] name The config key.
        # @param [ Hash ] config The configuration.
        #
        # @since 3.0.0
        def validate_database_name(name, config)
          unless config.has_key?(:name)
            raise Errors::NoDatabaseName.new(name, config)
          end
        end

        # Validate that the database config has a session.
        #
        # @api private
        #
        # @example Validate the database has a session.
        #   validator.validate_database_session(:default, {})
        #
        # @param [ String, Symbol ] session The config key.
        # @param [ Hash ] config The configuration.
        #
        # @since 3.0.0
        def validate_database_session(name, config)
          unless config.has_key?(:session)
            raise Errors::NoDatabaseSession.new(name, config)
          end
        end
      end
    end
  end
end
