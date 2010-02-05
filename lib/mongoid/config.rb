# encoding: utf-8
module Mongoid #:nodoc
  class Config #:nodoc
    include Singleton

    attr_accessor \
      :allow_dynamic_fields,
      :persist_in_safe_mode,
      :raise_not_found_error

    # Defaults the configuration options to true.
    def initialize
      @allow_dynamic_fields = true
      @persist_in_safe_mode = true
      @raise_not_found_error = true
    end

    # Sets the Mongo::DB to be used.
    def database=(db)
      raise Errors::InvalidDatabase.new(
          "Database should be a Mongo::DB, not #{db.class.name}"
        ) unless db.kind_of?(Mongo::DB)
      @database = db
    end

    # Returns the Mongo::DB to use or raise an error if none was set.
    def database
      @database || (raise Errors::InvalidDatabase.new("No database has been set, please use Mongoid.database="))
    end

  end
end
