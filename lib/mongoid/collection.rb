# encoding: utf-8
require "mongoid/collections/cyclic_iterator"
require "mongoid/collections/reader"
require "mongoid/collections/writer"

module Mongoid #:nodoc
  class Collection

    # Initialize a new Mongoid::Collection, setting up the master, slave, and
    # name attributes. Masters will be used for writes, slaves for reads.
    #
    # Example:
    #
    # <tt>Mongoid::Collection.new(masters, slaves, "test")</tt>
    def initialize(name)
      # Get all the master db -> Mongoid.master
      # Get all the slave dbs -> Mongoid.slaves
      @name = name
    end
  end
end
