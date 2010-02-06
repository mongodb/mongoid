# encoding: utf-8
require "mongoid/collections/operations"
require "mongoid/collections/cyclic_iterator"
require "mongoid/collections/mimic"
require "mongoid/collections/master"
require "mongoid/collections/slaves"

module Mongoid #:nodoc
  class Collection
    attr_reader :counter, :name

    # All write operations should delegate to the master connection. These
    # operations mimic the methods on a Mongo:Collection.
    #
    # Example:
    #
    # <tt>collection.save({ :name => "Al" })</tt>
    Collections::Operations::WRITE.each do |name|
      define_method(name) { |*args| master.send(name, *args) }
    end

    # All read operations should be intelligently directed to either the master
    # or the slave, depending on where the read counter is and what it's
    # maximum was configured at.
    #
    # Example:
    #
    # <tt>collection.find({ :name => "Al" })</tt>
    Collections::Operations::READ.each do |name|
      define_method(name) { |*args| directed.send(name, *args) }
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
    def directed
      if under_max_counter? || slaves.empty?
        @counter = @counter + 1
        master
      else
        @counter = 0
        slaves
      end
    end

    # Initialize a new Mongoid::Collection, setting up the master, slave, and
    # name attributes. Masters will be used for writes, slaves for reads.
    #
    # Example:
    #
    # <tt>Mongoid::Collection.new(masters, slaves, "test")</tt>
    def initialize(name)
      @name, @counter = name, 0
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

    # Return the object responsible for writes to the database. This will
    # always return a collection associated with the Master DB.
    #
    # Example:
    #
    # <tt>collection.writer</tt>
    def master
      @master ||= Collections::Master.new(Mongoid.master, @name)
    end

    protected
    def under_max_counter?
      @counter < Mongoid.max_successive_reads
    end
  end
end
