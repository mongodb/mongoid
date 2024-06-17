# frozen_string_literal: true
# rubocop:todo all

require "mongoid/config/defaults"
require "mongoid/config/environment"
require "mongoid/config/options"
require "mongoid/config/validators"
require "mongoid/config/introspection"
require "mongoid/config/encryption"

module Mongoid

  # This module defines all the configuration options for Mongoid, including
  # the database connections.
  module Config
    extend Forwardable
    extend Options
    extend Defaults
    extend Encryption
    extend self

    def_delegators ::Mongoid, :logger, :logger=

    LOCK = Mutex.new

    # Application name that is printed to the MongoDB logs upon establishing
    # a connection. Note that the name cannot exceed 128 bytes in length.
    # It is also used as the database name if the database name is not
    # explicitly defined.
    option :app_name, default: nil

    # (Deprecated) In MongoDB 4.0 and earlier, set whether to create
    # indexes in the background by default. (default: false)
    option :background_indexing, default: false

    # Mark belongs_to associations as required by default, so that saving a
    # model with a missing belongs_to association will trigger a validation
    # error.
    option :belongs_to_required_by_default, default: true

    # Set the global discriminator key.
    option :discriminator_key, default: "_type"

    # Raise an exception when a field is redefined.
    option :duplicate_fields_exception, default: false

    # Include the root model name in json serialization.
    option :include_root_in_json, default: false

    # # Include the _type field in serialization.
    option :include_type_for_serialization, default: false

    # Whether to join nested persistence contexts for atomic operations
    # to parent contexts by default.
    option :join_contexts, default: false

    # The log level.
    #
    # It must be set prior to referencing clients or Mongo.logger,
    # changes to this option are not be propagated to any clients and
    # loggers that already exist.
    #
    # Additionally, only when the clients are configured via the
    # configuration file is the log level given by this option honored.
    option :log_level, default: :info

    # Preload all models in development, needed when models use inheritance.
    option :preload_models, default: false

    # Raise an error when performing a #find and the document is not found.
    option :raise_not_found_error, default: true

    # Raise an error when defining a scope with the same name as an
    # existing method.
    option :scope_overwrite_exception, default: false

    # Return stored times as UTC.
    option :use_utc, default: false

    # Store BigDecimals as Decimal128s instead of strings in the db.
    option :map_big_decimal_to_decimal128, default: true

    # Allow BSON::Decimal128 to be parsed and returned directly in
    # field values. When BSON 5 is present and the this option is set to false
    # (the default), BSON::Decimal128 values in the database will be returned
    # as BigDecimal.
    #
    # @note this option only has effect when BSON 5+ is present. Otherwise,
    #   the setting is ignored.
    option :allow_bson5_decimal128, default: false, on_change: -> (allow) do
        if BSON::VERSION >= '5.0.0'
          if allow
            BSON::Registry.register(BSON::Decimal128::BSON_TYPE, BSON::Decimal128)
          else
            BSON::Registry.register(BSON::Decimal128::BSON_TYPE, BigDecimal)
          end
        end
      end

    # Sets the async_query_executor for the application. By default the thread pool executor
    #   is set to `:immediate. Options are:
    #
    #   - :immediate - Initializes a single +Concurrent::ImmediateExecutor+
    #   - :global_thread_pool - Initializes a single +Concurrent::ThreadPoolExecutor+
    #      that uses the +async_query_concurrency+ for the +max_threads+ value.
    option :async_query_executor, default: :immediate

    # Defines how many asynchronous queries can be executed concurrently.
    # This option should be set only if `async_query_executor` is set
    # to `:global_thread_pool`.
    option :global_executor_concurrency, default: nil

    # When this flag is false, a document will become read-only only once the
    # #readonly! method is called, and an error will be raised on attempting
    # to save or update such documents, instead of just on delete. When this
    # flag is true, a document is only read-only if it has been projected
    # using #only or #without, and read-only documents will not be
    # deletable/destroyable, but they will be savable/updatable.
    # When this feature flag is turned on, the read-only state will be reset on
    # reload, but when it is turned off, it won't be.
    option :legacy_readonly, default: false

    # When this flag is false (the default as of Mongoid 9.0), a document that
    # is created or loaded will remember the storage options that were active
    # when it was loaded, and will use those same options by default when
    # saving or reloading itself.
    #
    # When this flag is true you'll get pre-9.0 behavior, where a document will
    # not remember the storage options from when it was loaded/created, and
    # subsequent updates will need to explicitly set up those options each time.
    #
    # For example:
    #
    #    record = Model.with(collection: 'other_collection') { Model.first }
    #
    # This will try to load the first document from 'other_collection' and
    # instantiate it as a Model instance. Pre-9.0, the record object would
    # not remember that it came from 'other_collection', and attempts to
    # update it or reload it would fail unless you first remembered to
    # explicitly specify the collection every time.
    #
    # As of Mongoid 9.0, the record will remember that it came from
    # 'other_collection', and updates and reloads will automatically default
    # to that collection, for that record object.
    option :legacy_persistence_context_behavior, default: false

    # When this flag is true, any attempt to change the _id of a persisted
    # document will raise an exception (`Errors::ImmutableAttribute`).
    # This is the default in 9.0. Setting this flag to false restores the
    # pre-9.0 behavior, where changing the _id of a persisted
    # document might be ignored, or it might work, depending on the situation.
    option :immutable_ids, default: true

    # When this flag is true, callbacks for every embedded document will be
    # called only once, even if the embedded document is embedded in multiple
    # documents in the root document's dependencies graph.
    # This is the default in 9.0. Setting this flag to false restores the
    # pre-9.0 behavior, where callbacks are called for every occurrence of an
    # embedded document. The pre-9.0 behavior leads to a problem that for multi
    # level nested documents callbacks are called multiple times.
    # See https://jira.mongodb.org/browse/MONGOID-5542
    option :prevent_multiple_calls_of_embedded_callbacks, default: true

    # When this flag is false, callbacks for embedded documents will not be
    # called. This is the default in 9.0.
    #
    # Setting this flag to true restores the pre-9.0 behavior, where callbacks
    # for embedded documents are called. This may lead to stack overflow errors
    # if there are more than cicrca 1000 embedded documents in the root
    # document's dependencies graph.
    # See https://jira.mongodb.org/browse/MONGOID-5658 for more details.
    option :around_callbacks_for_embeds, default: false

    # When this flag is false, named scopes cannot unset a default scope.
    # This is the traditional (and default) behavior in Mongoid 9 and earlier.
    #
    # Setting this flag to true will allow named scopes to unset the default
    # scope. This will be the default in Mongoid 10.
    #
    # See https://jira.mongodb.org/browse/MONGOID-5785 for more details.
    option :allow_scopes_to_unset_default_scope, default: false

    # Returns the Config singleton, for use in the configure DSL.
    #
    # @return [ self ] The Config singleton.
    def config
      self
    end

    # Has Mongoid been configured? This is checking that at least a valid
    # client config exists.
    #
    # @example Is Mongoid configured?
    #   config.configured?
    #
    # @return [ true | false ] If Mongoid is configured.
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
    # @param [ String | Symbol ] environment The environment to load.
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
    def models
      @models ||= []
    end

    # Register a model in the application with Mongoid.
    #
    # @example Register a model.
    #   config.register_model(Band)
    #
    # @param [ Class ] klass The model to register.
    def register_model(klass)
      LOCK.synchronize do
        models.push(klass) unless models.include?(klass)
      end
    end

    # Deregister a model in the application with Mongoid.
    #
    # @param [ Class ] klass The model to deregister.
    #
    # @api private
    def deregister_model(klass)
      LOCK.synchronize do
        models.delete(klass)
      end
    end

    # From a hash of settings, load all the configuration.
    #
    # @example Load the configuration.
    #   config.load_configuration(settings)
    #
    # @param [ Hash ] settings The configuration settings.
    def load_configuration(settings)
      configuration = settings.with_indifferent_access
      self.options = configuration[:options]
      self.clients = configuration[:clients]
      Mongo.options = configuration[:driver_options] || {}
      set_log_levels
    end

    # Override the database to use globally.
    #
    # @example Override the database globally.
    #   config.override_database(:optional)
    #
    # @param [ String | Symbol ] name The name of the database.
    #
    # @return [ String | Symbol ] The global override.
    def override_database(name)
      Threaded.database_override = name
    end

    # Override the client to use globally.
    #
    # @example Override the client globally.
    #   config.override_client(:optional)
    #
    # @param [ String | Symbol ] name The name of the client.
    #
    # @return [ String | Symbol ] The global override.
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
    def purge!
      global_client.database.collections.each(&:drop) and true
    end

    # Truncate all data in all collections, but not the indexes.
    #
    # @example Truncate all collection data.
    #   Mongoid::Config.truncate!
    #
    # @note This will be slower than purge!
    #
    # @return [ true ] true.
    def truncate!
      global_client.database.collections.each do |collection|
        collection.find.delete_many
      end and true
    end

    # Set the configuration options. Will validate each one individually.
    #
    # @example Set the options.
    #   config.options = { raise_not_found_error: true }
    #
    # @param [ Hash ] options The configuration options.
    def options=(options)
      if options
        Validators::AsyncQueryExecutor.validate(options)
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
    def clients
      @clients ||= {}
    end

    # Get the time zone to use.
    #
    # @example Get the time zone.
    #   Config.time_zone
    #
    # @return [ String ] The time zone.
    def time_zone
      use_utc? ? "UTC" : ::Time.zone
    end

    # Is the application running under passenger?
    #
    # @example Is the application using passenger?
    #   config.running_with_passenger?
    #
    # @return [ true | false ] If the app is deployed on Passenger.
    #
    # @deprecated
    def running_with_passenger?
      @running_with_passenger ||= defined?(PhusionPassenger)
    end

    Mongoid.deprecate(self, :running_with_passenger?)

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

    # Get database client that respects global overrides
    # Config.override_database and Config.override_client.
    #
    # @return [Mongo::Client] Client according to global overrides.
    def global_client
      client =  if Threaded.client_override
                  Clients.with_name(Threaded.client_override)
                else
                  Clients.default
                end
      if Threaded.database_override
        client.use(Threaded.database_override)
      else
        client
      end
    end

    module DeprecatedOptions
      OPTIONS = %i[]

      if RUBY_VERSION < '3.0'
        def self.prepended(klass)
          klass.class_eval do
            OPTIONS.each do |option|
              alias_method :"#{option}_without_deprecation=", :"#{option}="

              define_method(:"#{option}=") do |value|
                Mongoid::Warnings.send(:"warn_#{option}_deprecated")
                send(:"#{option}_without_deprecation=", value)
              end
            end
          end
        end
      else
        OPTIONS.each do |option|
          define_method(:"#{option}=") do |value|
            Mongoid::Warnings.send(:"warn_#{option}_deprecated")
            super(value)
          end
        end
      end
    end

    prepend DeprecatedOptions
  end
end
