# encoding: utf-8
require "mongoid/collections/cyclic_iterator"
require "mongoid/collections/reader"
require "mongoid/collections/writer"

module Mongoid #:nodoc
  class Collection

    attr_reader :master, :name, :slaves

    # Initialize a new Mongoid::Collection, setting up the master, slave, and
    # name attributes. Masters will be used for writes, slaves for reads.
    #
    # Example:
    #
    # <tt>Mongoid::Collection.new(masters, slaves, "test")</tt>
    def initialize(name)
      @master, @slaves, @name = Mongoid.master, Mongoid.slaves, name
      @writer = Collections::Writer.new(@master, name)
      @reader = Collections::Reader.new((@slaves || [ @master ]), name)
    end
  end
end
