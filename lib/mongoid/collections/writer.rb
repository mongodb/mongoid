# encoding: utf-8
module Mongoid #:nodoc:
  module Collections #:nodoc:
    class Writer
      attr_reader :collection

      # Create the new database writer. Will create a collection from the
      # master database.
      #
      # Example:
      #
      # <tt>Writer.new(master, "mongoid_people")</tt>
      def initialize(master_db, name)
        @collection = master_db.collection(name)
      end

      # Send every method call to the master collection.
      #
      # Example:
      #
      # <tt>writer.find({})</tt>
      def method_missing(name, *args, &block)
        @collection.send(name, *args, &block)
      end
    end
  end
end
