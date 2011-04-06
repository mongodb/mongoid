# encoding: utf-8
require "uri"
require "mongoid/config/database"
require "mongoid/config/replset_database"

module Mongoid #:nodoc

  # This module defines all the configuration options for Mongoid, including the
  # database connections.
  #
  # @todo Durran: This module needs an overhaul, remove singleton, etc.
  module Config
    extend self
    include ActiveModel::Observing

    attr_accessor :master, :slaves, :settings
    @settings = {}

    # Define a configuration option with a default.
    #
    # @example Define the option.
    #   Config.option(:persist_in_safe_mode, :default => false)
    #
    # @param [ Symbol ] name The name of the configuration option.
    # @param [ Hash ] options Extras for the option.
    #
    # @option options [ Object ] :default The default value.
    #
    # @since 2.0.0.rc.1
    def option(name, options = {})
      define_method(name) do
        settings.has_key?(name) ? settings[name] : options[:default]
      end
      define_method("#{name}=") { |value| settings[name] = value }
      define_method("#{name}?") { send(name) }
    end

    option :allow_dynamic_fields, :default => true
    option :autocreate_indexes, :default => false
    option :binding_defaults, :default => { :binding => false, :continue => true }
    option :embedded_object_id, :default => true
    option :include_root_in_json, :default => false
    option :max_retries_on_connection_failure, :default => 0
    option :parameterize_keys, :default => true
    option :persist_in_safe_mode, :default => false
    option :preload_models, :default => true
    option :raise_not_found_error, :default => true
    option :skip_version_check, :default => false
    option :time_zone, :default => nil
    option :use_utc, :default => false

    # Adds a new I18n locale file to the load path.
    #
    # @example Add a portuguese locale.
    #   Mongoid::Config.add_language('pt')
    #
    # @example Add all available languages.
    #   Mongoid::Config.add_language('*')
    #
    # @param [ String ] language_code The language to add.
    def add_language(language_code = nil)
      Dir[
        File.join(
          File.dirname(__FILE__), "..", "config", "locales", "#{language_code}.yml"
      )
      ].each do |file|
        I18n.load_path << File.expand_path(file)
      end
    end

    # Get any extra databases that have been configured.
    #
    # @example Get the extras.
    #   config.databases
    #
    # @return [ Hash ] A hash of secondary databases.
    def databases
      configure_extras(@settings["databases"]) unless @databases || !@settings
      @databases || {}
    end

    # @todo Durran: There were no tests around the databases setter, not sure
    # what the exact expectation was. Set with a hash?
    def databases=(databases)
    end

    # Return field names that could cause destructive things to happen if
    # defined in a Mongoid::Document.
    #
    # @example Get the destructive fields.
    #   config.destructive_fields
    #
    # @return [ Array<String> ] An array of bad field names.
    def destructive_fields
      @destructive_fields ||= lambda {
        klass = Class.new do
          include Mongoid::Document
        end
        klass.instance_methods(true).collect { |method| method.to_s }
      }.call
    end

    # Configure mongoid from a hash. This is usually called after parsing a
    # yaml config file such as mongoid.yml.
    #
    # @example Configure Mongoid.
    #   config.from_hash({})
    #
    # @param [ Hash ] options The settings to use.
    def from_hash(options = {})
      options.except("database", "slaves", "databases").each_pair do |name, value|
        send("#{name}=", value) if respond_to?("#{name}=")
      end
      configure_databases(options)
      configure_extras(options["databases"])
    end

    # Load the settings from a compliant mongoid.yml file. This can be used for
    # easy setup with frameworks other than Rails.
    #
    # @example Configure Mongoid.
    #   Mongoid.load!("/path/to/mongoid.yml")
    #
    # @param [ String ] path The path to the file.
    #
    # @since 2.0.1
    def load!(path)
      environment = defined?(Rails) ? Rails.env : ENV["RACK_ENV"]
      settings = YAML.load(ERB.new(File.new(path).read).result)[environment]
      if settings.present?
        from_hash(settings)
      end
    end

    # Returns the logger, or defaults to Rails logger or stdout logger.
    #
    # @example Get the logger.
    #   config.logger
    #
    # @return [ Logger ] The desired logger.
    def logger
      @logger ||= defined?(Rails) ? Rails.logger : ::Logger.new($stdout)
    end

    # Sets the logger for Mongoid to use.
    #
    # @example Set the logger.
    #   config.logger = Logger.new($stdout, :warn)
    #
    # @return [ Logger ] The newly set logger.
    def logger=(logger)
      @logger = logger
    end

    # Sets whether the times returned from the database use the ruby or
    # the ActiveSupport time zone.
    # If you omit this setting, then times will use the ruby time zone.
    #
    # Example:
    #
    # <tt>Config.use_activesupport_time_zone = true</tt>
    #
    # Returns:
    #
    # A boolean
    def use_activesupport_time_zone=(value)
      @use_activesupport_time_zone = value || false
    end

    # Sets whether the times returned from the database use the ruby or
    # the ActiveSupport time zone.
    # If the setting is false, then times will use the ruby time zone.
    #
    # Example:
    #
    # <tt>Config.use_activesupport_time_zone</tt>
    #
    # Returns:
    #
    # A boolean
    attr_reader :use_activesupport_time_zone
    alias_method :use_activesupport_time_zone?, :use_activesupport_time_zone

    # Sets the Mongo::DB master database to be used. If the object trying to be
    # set is not a valid +Mongo::DB+, then an error will be raised.
    #
    # @example Set the master database.
    #   config.master = Mongo::Connection.db("test")
    #
    # @param [ Mongo::DB ] db The master database.
    #
    # @raise [ Errors::InvalidDatabase ] If the master isnt a valid object.
    #
    # @return [ Mongo::DB ] The master instance.
    def master=(db)
      check_database!(db)
      @master = db
    end
    alias :database= :master=

    # Returns the master database, or if none has been set it will raise an
    # error.
    #
    # @example Get the master database.
    #   config.master
    #
    # @raise [ Errors::InvalidDatabase ] If the database was not set.
    #
    # @return [ Mongo::DB ] The master database.
    def master
      unless @master
        configure_databases(@settings) unless @settings.blank?
        raise Errors::InvalidDatabase.new(nil) unless @master
      end
      if @reconnect
        @reconnect = false
        reconnect!
      end
      @master
    end
    alias :database :master

    # Convenience method for connecting to the master database after forking a
    # new process.
    #
    # @example Reconnect to the master.
    #   Mongoid.reconnect!
    #
    # @param [ true, false ] now Perform the reconnection immediately?
    def reconnect!(now = true)
      if now
        master.connection.connect
      else
        # We set a @reconnect flag so that #master knows to reconnect the next
        # time the connection is accessed.
        @reconnect = true
      end
    end

    # Reset the configuration options to the defaults.
    #
    # @example Reset the configuration options.
    #   config.reset
    def reset
      settings.clear
    end

    # Sets the Mongo::DB slave databases to be used. If the objects provided
    # are not valid +Mongo::DBs+ an error will be raised.
    #
    # @example Set the slaves.
    #   config.slaves = [ Mongo::Connection.db("test") ]
    #
    # @param [ Array<Mongo::DB> ] dbs The slave databases.
    #
    # @raise [ Errors::InvalidDatabase ] If the slaves arent valid objects.
    #
    # @return [ Array<Mongo::DB> ] The slave DB instances.
    def slaves=(dbs)
      return unless dbs
      dbs.each do |db|
        check_database!(db)
      end
      @slaves = dbs
    end

    # Returns the slave databases or nil if none have been set.
    #
    # @example Get the slaves.
    #   config.slaves
    #
    # @return [ Array<Mongo::DB>, nil ] The slave databases.
    def slaves
      unless @slaves
        configure_databases(@settings) if @settings && @settings[:database]
      end
      @slaves
    end

    protected

    # Check if the database is valid and the correct version.
    #
    # @example Check if the database is valid.
    #   config.check_database!
    #
    # @param [ Mongo::DB ] database The db to check.
    #
    # @raise [ Errors::InvalidDatabase ] If the object is not valid.
    # @raise [ Errors::UnsupportedVersion ] If the db version is too old.
    def check_database!(database)
      raise Errors::InvalidDatabase.new(database) unless database.kind_of?(Mongo::DB)
      unless skip_version_check
        version = database.connection.server_version
        raise Errors::UnsupportedVersion.new(version) if version < Mongoid::MONGODB_VERSION
      end
    end

    # Get a database from settings.
    #
    # @example Configure the master and slave dbs.
    #   config.configure_databases("database" => "mongoid")
    #
    # @param [ Hash ] options The options to use.
    #
    # @option options [ String ] :database The database name.
    # @option options [ String ] :host The database host.
    # @option options [ String ] :password The password for authentication.
    # @option options [ Integer ] :port The port for the database.
    # @option options [ Array<Hash> ] :slaves The slave db options.
    # @option options [ String ] :uri The uri for the database.
    # @option options [ String ] :username The user for authentication.
    #
    # @since 2.0.0.rc.1
    def configure_databases(options)
      if options.has_key?('hosts')
        @master, @slaves = ReplsetDatabase.new(options).configure
      else
        @master, @slaves = Database.new(options).configure
      end
    end

    # Get the secondary databases from settings.
    #
    # @example Configure the master and slave dbs.
    #   config.configure_extras("databases" => settings)
    #
    # @param [ Hash ] options The options to use.
    #
    # @since 2.0.0.rc.1
    def configure_extras(extras)
      @databases = (extras || []).inject({}) do |dbs, (name, options)|
        dbs.tap do |extra|
        dbs[name], dbs["#{name}_slaves"] = Database.new(options).configure
        end
      end
    end
  end
end
