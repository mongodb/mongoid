# encoding: utf-8
module Mongoid #:nodoc
  class Config #:nodoc
    include Singleton

    attr_accessor \
      :allow_dynamic_fields,
      :reconnect_time,
      :parameterize_keys,
      :persist_in_safe_mode,
      :persist_types,
      :raise_not_found_error,
      :use_object_ids

    # Defaults the configuration options to true.
    def initialize
      @allow_dynamic_fields = true
      @parameterize_keys = true
      @persist_in_safe_mode = true
      @persist_types = true
      @raise_not_found_error = true
      @reconnect_time = 3
      @use_object_ids = false
    end

    # Sets the Mongo::DB master database to be used. If the object trying to me
    # set is not a valid +Mongo::DB+, then an error will be raise.
    #
    # Example:
    #
    # <tt>Config.master = Mongo::Connection.db("test")</tt>
    #
    # Returns:
    #
    # The Master DB instance.
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

    # Sets the Mongo::DB slave databases to be used. If the objects trying to me
    # set are not valid +Mongo::DBs+, then an error will be raise.
    #
    # Example:
    #
    # <tt>Config.slaves = [ Mongo::Connection.db("test") ]</tt>
    #
    # Returns:
    #
    # The slaves DB instances.
    def slaves=(dbs)
      dbs.each do |db|
        check_database!(db)
      end
      @slaves = dbs
    end

    # Returns the slave databases, or if none has been set nil
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
        klass.instance_methods(true)
      }.call
    end

    protected
    def check_database!(database)
      raise Errors::InvalidDatabase.new(database) unless database.kind_of?(Mongo::DB)
      version = database.connection.server_version
      raise Errors::UnsupportedVersion.new(version) if version < Mongoid::MONGODB_VERSION
    end
  end
end
