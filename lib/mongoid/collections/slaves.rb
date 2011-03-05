# encoding: utf-8
module Mongoid #:nodoc:
  module Collections #:nodoc:

    # This class wraps the MongoDB slaves databases.
    class Slaves
      include Mongoid::Collections::Retry

      attr_reader :iterator

      # All read operations should delegate to the slave connections.
      # These operations mimic the methods on a Mongo:Collection.
      #
      # @example Proxy the driver save.
      #   collection.save({ :name => "Al" })
      Operations::READ.each do |name|
        define_method(name) do |*args|
          retry_on_connection_failure do
            collection.send(name, *args)
          end
        end
      end

      # Is the collection of slaves empty or not?
      #
      # @example Is the collection empty?
      #   slaves.empty?
      #
      # @return [ true, false ] If the iterator is set or not.
      def empty?
        iterator.nil?
      end

      # Create the new database reader. Will create a collection from the
      # slave databases and cycle through them on each read.
      #
      # @example Create the slaves.
      #   Reader.new(slaves, "mongoid_people")
      #
      # @param [ Array<Mongo::DB> ] slaves The slave databases.
      # @param [ String ] name The database name.
      def initialize(slaves, name)
        unless slaves.blank?
          @iterator = CyclicIterator.new(slaves.collect { |db| db.collection(name) })
        end
      end

      protected

      # Get the next database in the round-robin.
      #
      # @example Get the next database.
      #   slaves.collection
      #
      # @return [ Mongo::DB ] The next slave database to read from.
      def collection
        iterator.next
      end
    end
  end
end
