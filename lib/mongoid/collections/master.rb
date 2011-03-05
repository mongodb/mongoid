# encoding: utf-8
module Mongoid #:nodoc:
  module Collections #:nodoc:

    # This class wraps the MongoDB master database.
    class Master
      include Mongoid::Collections::Retry

      attr_reader :collection

      # All read and write operations should delegate to the master connection.
      # These operations mimic the methods on a Mongo:Collection.
      #
      # @example Proxy the driver save.
      #   collection.save({ :name => "Al" })
      Operations::ALL.each do |name|
        define_method(name) do |*args|
          retry_on_connection_failure do
            collection.send(name, *args)
          end
        end
      end

      # Create the new database writer. Will create a collection from the
      # master database.
      #
      # @example Create a new wrapped master.
      #   Master.new(db, "testing")
      #
      # @param [ Mongo::DB ] master The master database.
      # @param [ String ] name The name of the database.
      def initialize(master, name)
        @collection = master.collection(name)
      end
    end
  end
end
