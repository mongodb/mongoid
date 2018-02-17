# encoding: utf-8
require "mongoid/config/environment"
require "mongoid/config/options"
require "mongoid/config/validators"

module Mongoid

  # This module defines all the configuration options for Mongoid, including the
  # database connections.
  module Config
    extend self
    extend Options

    delegate :logger=, to: ::Mongoid
    delegate :logger, to: ::Mongoid

    LOCK = Mutex.new

    option :include_root_in_json, default: false
    option :include_type_for_serialization, default: false
    option :preload_models, default: false
    option :raise_not_found_error, default: true
    option :scope_overwrite_exception, default: false
    option :duplicate_fields_exception, default: false
    option :use_activesupport_time_zone, default: true
    option :use_utc, default: false
    option :log_level, default: :info
    option :belongs_to_required_by_default, default: true
    option :app_name, default: nil
    option :background_indexing, default: false

    # Has Mongoid been configured? This is checking that at least a valid
    # client config exists.
    #
    # @example Is Mongoid configured?
    #   config.configured?
    #
    # @return [ true, false ] If Mongoid is configured.
    #
    # @since 3.0.9
    def configured?
      clients.key?(:default)
    end

    # Connect to the provided database name on the default client.
    #
    # @note Use only in development or test environments for convenience.
    #
    # @example Set the database to connect to.
    #   config.connect_to("mongoid_test")
    #
    # @param [ String ] name The database name.
    #
    # @since 3.0.0
    def connect_to(name, options = { read: { mode: :primary }})
      self.clients = {
        default: {
          database: name,
          hosts: [ "localhost:27017" ],
          options: options
        }
      }
    end

    # Return field names that could cause destructive things to happen if
    # defined in a Mongoid::Document.
    #
    # @example Get the destructive fields.
    #   config.destructive_fields
    #
    # @return [ Array<String> ] An array of bad field names.
    def destructive_fields
      Composable.prohibited_methods
    end

    # Load the settings from a compliant mongoid.yml file. This can be used for
    # easy setup with frameworks other than Rails.
    #
    # @example Configure Mongoid.
    #   Mongoid.load!("/path/to/mongoid.yml")
    #
    # @param [ String ] path The path to the file.
    # @param [ String, Symbol ] environment The environment to load.
    #
    # @since 2.0.1
    def load!(path, environment = nil)
      settings = Environment.load_yaml(path, environment)
      if settings.present?
        Clients.disconnect
        Clients.clear
        load_configuration(settings)
      end
      settings
    end

    # Get all the models in the application - this is everything that includes
    # Mongoid::Document.
    #
    # @example Get all the models.
    #   config.models
    #
    # @return [ Array<Class> ] All the models in the application.
    #
    # @since 3.1.0
    def models
      @models ||= []
    end

    # Register a model in the application with Mongoid.
    #
    # @example Register a model.
    #   config.register_model(Band)
    #
    # @param [ Class ] klass The model to register.
    #
    # @since 3.1.0
    def register_model(klass)
      LOCK.synchronize do
        models.push(klass) unless models.include?(klass)
      end
    end

    # From a hash of settings, load all the configuration.
    #
    # @example Load the configuration.
    #   config.load_configuration(settings)
    #
    # @param [ Hash ] settings The configuration settings.
    #
    # @since 3.1.0
    def load_configuration(settings)
      configuration = settings.with_indifferent_access
      self.options = configuration[:options]
      self.clients = configuration[:clients]
      set_log_levels
    end

    # Override the database to use globally.
    #
    # @example Override the database globally.
    #   config.override_database(:optional)
    #
    # @param [ String, Symbol ] name The name of the database.
    #
    # @return [ String, Symbol ] The global override.
    #
    # @since 3.0.0
    def override_database(name)
      Threaded.database_override = name
    end

    # Override the client to use globally.
    #
    # @example Override the client globally.
    #   config.override_client(:optional)
    #
    # @param [ String, Symbol ] name The name of the client.
    #
    # @return [ String, Symbol ] The global override.
    #
    # @since 3.0.0
    def override_client(name)
      Threaded.client_override = name ? name.to_s : nil
    end

    # Purge all data in all collections, including indexes.
    #
    # @example Purge all data.
    #   Mongoid::Config.purge!
    #
    # @note This is the fastest way to drop all data.
    #
    # @return [ true ] true.
    #
    # @since 2.0.2
    def purge!
      Clients.default.database.collections.each(&:drop) and true
    end

    # Truncate all data in all collections, but not the indexes.
    #
    # @example Truncate all collection data.
    #   Mongoid::Config.truncate!
    #
    # @note This will be slower than purge!
    #
    # @return [ true ] true.
    #
    # @since 2.0.2
    def truncate!
      Clients.default.database.collections.each do |collection|
        collection.find.delete_many
      end and true
    end

    # Set the configuration options. Will validate each one individually.
    #
    # @example Set the options.
    #   config.options = { raise_not_found_error: true }
    #
    # @param [ Hash ] options The configuration options.
    #
    # @since 3.0.0
    def options=(options)
      if options
        options.each_pair do |option, value|
          Validators::Option.validate(option)
          send("#{option}=", value)
        end
      end
    end

    # Get the client configuration or an empty hash.
    #
    # @example Get the clients configuration.
    #   config.clients
    #
    # @return [ Hash ] The clients configuration.
    #
    # @since 3.0.0
    def clients
      @clients ||= {}
    end

    # Get the time zone to use.
    #
    # @example Get the time zone.
    #   Config.time_zone
    #
    # @return [ String ] The time zone.
    #
    # @since 3.0.0
    def time_zone
      use_utc? ? "UTC" : ::Time.zone
    end

    # Is the application running under passenger?
    #
    # @example Is the application using passenger?
    #   config.running_with_passenger?
    #
    # @return [ true, false ] If the app is deployed on Passenger.
    #
    # @since 3.0.11
    def running_with_passenger?
      @running_with_passenger ||= defined?(PhusionPassenger)
    end

    private

    def set_log_levels
      Mongoid.logger.level = Mongoid::Config.log_level unless defined?(::Rails)
      Mongo::Logger.logger.level = Mongoid.logger.level
    end

    def clients=(clients)
      raise Errors::NoClientsConfig.new unless clients
      c = clients.with_indifferent_access
      Validators::Client.validate(c)
      @clients = c
    end
  end
end
