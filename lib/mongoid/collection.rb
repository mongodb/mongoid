# encoding: utf-8
require "mongoid/collections/retry"
require "mongoid/collections/operations"
require "mongoid/collections/cyclic_iterator"
require "mongoid/collections/master"
require "mongoid/collections/slaves"

module Mongoid #:nodoc

  # This class is the Mongoid wrapper to the Mongo Ruby driver's collection
  # object.
  class Collection
    attr_reader :counter, :name

    # All write operations should delegate to the master connection. These
    # operations mimic the methods on a Mongo:Collection.
    #
    # @example Delegate the operation.
    #   collection.save({ :name => "Al" })
    Collections::Operations::PROXIED.each do |name|
      define_method(name) { |*args| master.send(name, *args) }
    end

    # Determines where to send the next read query. If the slaves are not
    # defined then send to master. If the read counter is under the configured
    # maximum then return the master. In any other case return the slaves.
    #
    # @example Send the operation to the master or slaves.
    #   collection.directed
    #
    # @param [ Hash ] options The operation options.
    #
    # @option options [ true, false ] :cache Should the query cache in memory?
    # @option options [ true, false ] :enslave Send the write to the slave?
    #
    # @return [ Master, Slaves ] The connection to use.
    def directed(options = {})
      options.delete(:cache)
      enslave = options.delete(:enslave) || @klass.enslaved?
      enslave ? master_or_slaves : master
    end

    # Find documents from the database given a selector and options.
    #
    # @example Find documents in the collection.
    #   collection.find({ :test => "value" })
    #
    # @param [ Hash ] selector The query selector.
    # @param [ Hash ] options The options to pass to the db.
    #
    # @return [ Cursor ] The results.
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
    # @example Find one document.
    #   collection.find_one({ :test => "value" })
    #
    # @param [ Hash ] selector The query selector.
    # @param [ Hash ] options The options to pass to the db.
    #
    # @return [ Document, nil ] A matching document or nil if none found.
    def find_one(selector = {}, options = {})
      directed(options).find_one(selector, options)
    end

    # Initialize a new Mongoid::Collection, setting up the master, slave, and
    # name attributes. Masters will be used for writes, slaves for reads.
    #
    # @example Create the new collection.
    #   Collection.new(masters, slaves, "test")
    #
    # @param [ Class ] klass The class the collection is for.
    # @param [ String ] name The name of the collection.
    def initialize(klass, name)
      @klass, @name = klass, name
    end

    # Perform a map/reduce on the documents.
    #
    # @example Perform the map/reduce.
    #   collection.map_reduce(map, reduce)
    #
    # @param [ String ] map The map javascript function.
    # @param [ String ] reduce The reduce javascript function.
    # @param [ Hash ] options The options to pass to the db.
    #
    # @return [ Cursor ] The results.
    def map_reduce(map, reduce, options = {})
      directed(options).map_reduce(map, reduce, options)
    end
    alias :mapreduce :map_reduce

    # Return the object responsible for writes to the database. This will
    # always return a collection associated with the Master DB.
    #
    # @example Get the master connection.
    #   collection.master
    #
    # @return [ Master ] The master connection.
    def master
      db = Mongoid.databases[@klass.database] || Mongoid.master
      @master ||= Collections::Master.new(db, @name)
    end

    # Return the object responsible for reading documents from the database.
    # This is usually the slave databases, but in their absence the master will
    # handle the task.
    #
    # @example Get the slaves array.
    #   collection.slaves
    #
    # @return [ Slaves ] The pool of slave connections.
    def slaves
      slaves = Mongoid.databases["#{@klass.database}_slaves"] || Mongoid.slaves
      @slaves ||= Collections::Slaves.new(slaves, @name)
    end

    # Updates one or more documents in the collection.
    #
    # @example Update documents.
    #   collection.update(
    #     { "_id" => BSON::OjectId.new },
    #     { "$push" => { "addresses" => { "_id" => "street" } } },
    #     :safe => true
    #   )
    #
    # @param [ Hash ] selector The document selector.
    # @param [ Hash ] document The modifier.
    # @param [ Hash ] options The options.
    #
    # @since 2.0.0
    def update(selector, document, options = {})
      updater = Thread.current[:mongoid_atomic_update]
      if updater
        updater.consume(selector, document, options)
      else
        master.update(selector, document, options)
      end
    end

    protected

    # Determine if the read is going to the master or the slaves.
    #
    # @example Use the master or slaves?
    #   collection.master_or_slaves
    #
    # @return [ Master, Slaves ] Master if not slaves exist, or slaves.
    def master_or_slaves
      slaves.empty? ? master : slaves
    end
  end
end
