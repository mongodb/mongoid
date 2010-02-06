# encoding: utf-8
module Mongoid #:nodoc:
  module Collections #:nodoc:
    class Master
      extend Mimic

      attr_reader :collection

      # All read and write operations should delegate to the master connection.
      # These operations mimic the methods on a Mongo:Collection.
      #
      # Example:
      #
      # <tt>collection.save({ :name => "Al" })</tt>
      proxy(:collection, Operations::ALL)

      # Create the new database writer. Will create a collection from the
      # master database.
      #
      # Example:
      #
      # <tt>Master.new(master, "mongoid_people")</tt>
      def initialize(master, name)
        @collection = master.collection(name)
      end
    end
  end
end
