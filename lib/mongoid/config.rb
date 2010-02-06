# encoding: utf-8
module Mongoid #:nodoc
  class Config #:nodoc
    include Singleton

    attr_accessor \
      :allow_dynamic_fields,
      :max_successive_reads,
      :persist_in_safe_mode,
      :raise_not_found_error

    # Defaults the configuration options to true.
    def initialize
      @allow_dynamic_fields = true
      @max_successive_reads = 10
      @persist_in_safe_mode = true
      @raise_not_found_error = true
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
      raise Errors::InvalidDatabase.new(db) unless db.kind_of?(Mongo::DB)
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
      dbs.each { |db| raise Errors::InvalidDatabase.new(db) unless db.kind_of?(Mongo::DB) }
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
  end
end
