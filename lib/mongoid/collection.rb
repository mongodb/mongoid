# encoding: utf-8
require "mongoid/collections/operations"
require "mongoid/collections/cyclic_iterator"
require "mongoid/collections/master"
require "mongoid/collections/slaves"

module Mongoid #:nodoc
  # The Mongoid wrapper to the Mongo Ruby driver's collection object.
  class Collection
    attr_reader :counter, :name

    # All write operations should delegate to the master connection. These
    # operations mimic the methods on a Mongo:Collection.
    #
    # Example:
    #
    # <tt>collection.save({ :name => "Al" })</tt>
    Collections::Operations::PROXIED.each do |name|
      define_method(name) { |*args| master.send(name, *args) }
    end

    # Determines where to send the next read query. If the slaves are not
    # defined then send to master. If the read counter is under the configured
    # maximum then return the master. In any other case return the slaves.
    #
    # Example:
    #
    # <tt>collection.directed</tt>
    #
    # Return:
    #
    # Either a +Master+ or +Slaves+ collection.
    def directed(options = {})
      options.delete(:cache)
      enslave = options.delete(:enslave) || @klass.enslaved?
      enslave ? master_or_slaves : master
    end

    # Find documents from the database given a selector and options.
    #
    # Options:
    #
    # selector: A +Hash+ selector that is the query.
    # options: The options to pass to the db.
    #
    # Example:
    #
    # <tt>collection.find({ :test => "value" })</tt>
    def find(selector = {}, options = {})
      cursor = Mongoid::Cursor.new(@klass, self, directed(options).find(selector, options))
      if block_given?
        yield cursor; cursor.close
      else
        cursor
      end
    end

    # Find the first document from the database given a selector and options.
    #
    # Options:
    #
    # selector: A +Hash+ selector that is the query.
    # options: The options to pass to the db.
    #
    # Example:
    #
    # <tt>collection.find_one({ :test => "value" })</tt>
    def find_one(selector = {}, options = {})
      directed(options).find_one(selector, options)
    end

    # Initialize a new Mongoid::Collection, setting up the master, slave, and
    # name attributes. Masters will be used for writes, slaves for reads.
    #
    # Example:
    #
    # <tt>Mongoid::Collection.new(masters, slaves, "test")</tt>
    def initialize(klass, name)
      @klass, @name = klass, name
    end

    # Perform a map/reduce on the documents.
    #
    # Options:
    #
    # map: The map javascript function.
    # reduce: The reduce javascript function.
    def map_reduce(map, reduce, options = {})
      directed(options).map_reduce(map, reduce, options)
    end

    alias :mapreduce :map_reduce

    # Return the object responsible for writes to the database. This will
    # always return a collection associated with the Master DB.
    #
    # Example:
    #
    # <tt>collection.writer</tt>
    def master
      @master ||= Collections::Master.new(Mongoid.master, @name)
    end

    # Return the object responsible for reading documents from the database.
    # This is usually the slave databases, but in their absence the master will
    # handle the task.
    #
    # Example:
    #
    # <tt>collection.reader</tt>
    def slaves
      @slaves ||= Collections::Slaves.new(Mongoid.slaves, @name)
    end

    protected
    def master_or_slaves
      slaves.empty? ? master : slaves
    end
  end
end
