# encoding: utf-8
require "uri"

module Mongoid #:nodoc
  class Config #:nodoc
    include Singleton

    attr_accessor \
      :allow_dynamic_fields,
      :reconnect_time,
      :parameterize_keys,
      :persist_in_safe_mode,
      :raise_not_found_error,
      :use_object_ids,
      :skip_version_check

    # Initializes the configuration with default settings.
    def initialize
      reset
    end

    # Sets whether the times returned from the database are in UTC or local time.
    # If you omit this setting, then times will be returned in
    # the local time zone.
    #
    # Example:
    #
    # <tt>Config.use_utc = true</tt>
    #
    # Returns:
    #
    # A boolean
    def use_utc=(value)
      @use_utc = value || false
    end

    # Returns whether times are return from the database in UTC. If
    # this setting is false, then times will be returned in the local time zone.
    #
    # Example:
    #
    # <tt>Config.use_utc</tt>
    #
    # Returns:
    #
    # A boolean
    attr_reader :use_utc
    alias_method :use_utc?, :use_utc

    # Sets the Mongo::DB master database to be used. If the object trying to be
    # set is not a valid +Mongo::DB+, then an error will be raised.
    #
    # Example:
    #
    # <tt>Config.master = Mongo::Connection.db("test")</tt>
    #
    # Returns:
    #
    # The master +Mongo::DB+ instance.
    def master=(db)
      check_database!(db)
      @master = db
    end

    # Returns the master database, or if none has been set it will raise an
    # error.
    #
    # Example:
    #
    # <tt>Config.master</tt>
    #
    # Returns:
    #
    # The master +Mongo::DB+
    def master
      @master || (raise Errors::InvalidDatabase.new(nil))
    end

    alias :database :master
    alias :database= :master=

    # Sets the Mongo::DB slave databases to be used. If the objects provided
    # are not valid +Mongo::DBs+ an error will be raised.
    #
    # Example:
    #
    # <tt>Config.slaves = [ Mongo::Connection.db("test") ]</tt>
    #
    # Returns:
    #
    # The slave DB instances.
    def slaves=(dbs)
      return unless dbs
      dbs.each do |db|
        check_database!(db)
      end
      @slaves = dbs
    end

    # Returns the slave databases or nil if none have been set.
    #
    # Example:
    #
    # <tt>Config.slaves</tt>
    #
    # Returns:
    #
    # The slave +Mongo::DBs+
    def slaves
      @slaves
    end

    # Returns the logger, or defaults to Rails logger or stdout logger.
    #
    # Example:
    #
    # <tt>Config.logger</tt>
    def logger
      return @logger if defined?(@logger)

      @logger = defined?(Rails) ? Rails.logger : ::Logger.new($stdout)
    end

    # Sets the logger for Mongoid to use.
    #
    # Example:
    #
    # <tt>Config.logger = Logger.new($stdout, :warn)</tt>
    def logger=(logger)
      @logger = logger
    end

    # Return field names that could cause destructive things to happen if
    # defined in a Mongoid::Document
    #
    # Example:
    #
    # <tt>Config.destructive_fields</tt>
    #
    # Returns:
    #
    # An array of bad field names.
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
    # Example:
    #
    # <tt>Mongoid::Config.instance.from_hash({})</tt>
    def from_hash(settings)
      _master(settings)
      _slaves(settings)
      settings.except("database", "slaves").each_pair do |name, value|
        send("#{name}=", value) if respond_to?(name)
      end
    end

    # Convenience method for connecting to the master database after forking a
    # new process.
    #
    # Example:
    #
    # <tt>Mongoid.reconnect!</tt>
    def reconnect!
      master.connection.connect_to_master
    end

    # Reset the configuration options to the defaults.
    #
    # Example:
    #
    # <tt>config.reset</tt>
    def reset
      @allow_dynamic_fields = true
      @parameterize_keys = true
      @persist_in_safe_mode = true
      @raise_not_found_error = true
      @reconnect_time = 3
      @use_object_ids = false
      @skip_version_check = false
      @time_zone = nil
    end

    ##
    # If Mongoid.use_object_ids = true
    #   Convert args to BSON::ObjectID
    #   If this args is an array, convert all args inside
    # Else
    #   return args
    #
    # Options:
    #
    #  args : A +String+ or an +Array+ convert to +BSON::ObjectID+
    #  cast :  A +Boolean+ define if we can or not cast to BSON::ObjectID. If false, we use the default type of args
    #
    # Example:
    #
    # <tt>Mongoid.convert_to_object_id("4ab2bc4b8ad548971900005c", true)</tt>
    # <tt>Mongoid.convert_to_object_id(["4ab2bc4b8ad548971900005c", "4ab2bc4b8ad548971900005d"])</tt>
    #
    # Returns:
    #
    # If Mongoid.use_object_ids = true
    #   An +Array+ of +BSON::ObjectID+ of each element if params is an +Array+
    #   A +BSON::ObjectID+ from params if params is +String+
    # Else
    #   <tt>args</tt>
    #
    def convert_to_object_id(args, cast=true)
      return args if !use_object_ids || args.is_a?(BSON::ObjectID) || !cast
      if args.is_a?(String)
        BSON::ObjectID(args)
      else
        args.map{ |a|
          a.is_a?(BSON::ObjectID) ? a : BSON::ObjectID(a)
        }
      end
    end

    protected

    # Check if the database is valid and the correct version.
    #
    # Example:
    #
    # <tt>config.check_database!</tt>
    def check_database!(database)
      raise Errors::InvalidDatabase.new(database) unless database.kind_of?(Mongo::DB)
      unless Mongoid.skip_version_check
        version = database.connection.server_version
        raise Errors::UnsupportedVersion.new(version) if version < Mongoid::MONGODB_VERSION
      end
    end

    # Get a master database from settings.
    #
    # TODO: Durran: This code's a bit hairy, refactor.
    #
    # Example:
    #
    # <tt>config._master({}, "test")</tt>
    def _master(settings)
      mongo_uri = settings["uri"].present? ? URI.parse(settings["uri"]) : OpenStruct.new

      name = settings["database"] || mongo_uri.path.to_s.sub("/", "")
      host = settings["host"] || mongo_uri.host || "localhost"
      port = settings["port"] || mongo_uri.port || 27017
      pool_size = settings["pool_size"] || 1
      username = settings["username"] || mongo_uri.user
      password = settings["password"] || mongo_uri.password

      connection = Mongo::Connection.new(host, port, :logger => Mongoid::Logger.new, :pool_size => pool_size)
      if username || password
        connection.add_auth(name, username, password)
        connection.apply_saved_authentication
      end
      self.master = connection.db(name)
    end

    # Get a bunch-o-slaves from settings and names.
    #
    # TODO: Durran: This code's a bit hairy, refactor.
    #
    # Example:
    #
    # <tt>config._slaves({}, "test")</tt>
    def _slaves(settings)
      mongo_uri = settings["uri"].present? ? URI.parse(settings["uri"]) : OpenStruct.new
      name = settings["database"] || mongo_uri.path.to_s.sub("/", "")
      self.slaves = []
      slaves = settings["slaves"]
      slaves.to_a.each do |slave|
        slave_uri = slave["uri"].present? ? URI.parse(slave["uri"]) : OpenStruct.new
        slave_username = slave["username"] || slave_uri.user
        slave_password = slave["password"] || slave_uri.password

        slave_connection = Mongo::Connection.new(
          slave["host"] || slave_uri.host || "localhost",
          slave["port"] || slave_uri.port,
          :slave_ok => true
        )

        if slave_username || slave_password
          slave_connection.add_auth(name, slave_username, slave_password)
          slave_connection.apply_saved_authentication
        end
        self.slaves << slave_connection.db(name)
      end
    end
  end
end
