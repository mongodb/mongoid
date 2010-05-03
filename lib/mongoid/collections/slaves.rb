# encoding: utf-8
module Mongoid #:nodoc:
  module Collections #:nodoc:
    class Slaves

      attr_reader :iterator

      # All read operations should delegate to the slave connections.
      # These operations mimic the methods on a Mongo:Collection.
      #
      # Example:
      #
      # <tt>collection.save({ :name => "Al" })</tt>
      Operations::READ.each do |name|
        define_method(name) { |*args| collection.send(name, *args) }
      end

      # Is the collection of slaves empty or not?
      #
      # Return:
      #
      # True is the iterator is not set, false if not.
      def empty?
        @iterator.nil?
      end

      # Create the new database reader. Will create a collection from the
      # slave databases and cycle through them on each read.
      #
      # Example:
      #
      # <tt>Reader.new(slaves, "mongoid_people")</tt>
      def initialize(slaves, name)
        unless slaves.blank?
          @iterator = CyclicIterator.new(slaves.collect { |db| db.collection(name) })
        end
      end

      protected
      def collection
        @iterator.next
      end
    end
  end
end
