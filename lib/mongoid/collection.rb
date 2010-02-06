# encoding: utf-8
require "mongoid/collections/cyclic_iterator"
require "mongoid/collections/reader"
require "mongoid/collections/writer"

module Mongoid #:nodoc
  class Collection

    attr_reader :master, :name, :slaves

    delegate \
      :[],
      :count,
      :distinct,
      :find,
      :find_one,
      :group,
      :index_information,
      :map_reduce,
      :mapreduce,
      :options, :to => :reader

    delegate \
      :<<,
      :create_index,
      :drop,
      :drop_index,
      :drop_indexes,
      :insert,
      :remove,
      :rename,
      :save,
      :update, :to => :writer

    # Initialize a new Mongoid::Collection, setting up the master, slave, and
    # name attributes. Masters will be used for writes, slaves for reads.
    #
    # Example:
    #
    # <tt>Mongoid::Collection.new(masters, slaves, "test")</tt>
    def initialize(name)
      @master, @slaves, @name = Mongoid.master, Mongoid.slaves, name
    end

    # Return the object responsible for reading documents from the database.
    # This is usually the slave databases, but in their absence the master will
    # handle the task.
    #
    # Example:
    #
    # <tt>collection.reader</tt>
    def reader
      @reader ||= Collections::Reader.new((@slaves || [ @master ]), @name)
    end

    # Return the object responsible for writes to the database. This will
    # always return a collection associated with the Master DB.
    #
    # Example:
    #
    # <tt>collection.writer</tt>
    def writer
      @writer ||= Collections::Writer.new(@master, @name)
    end
  end
end
