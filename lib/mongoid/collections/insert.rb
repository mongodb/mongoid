# encoding: utf-8
module Mongoid #:nodoc:
  module Collections #:nodoc:

    # This class encapsulates Mongoid insert behaviour.
    class Insert

      attr_reader :documents, :master, :options

      # Create the new inserter.
      #
      # @example Create the new inserter.
      #   Insert.new(documents, master, options)
      #
      # @param [ Array<Document> ] documents The documents to insert.
      # @param [ Master ] master The collection for the master db.
      # @param [ Hash ] options The persistence options.
      #
      # @since 2.1.0
      def initialize(documents, master, options = {})
        @documents, @master, @options = documents, master, options
      end

      # Execute the insert operation. If a batch consumer is sitting on the
      # current thread we will allow it to consume the operation. If not we
      # will persist to the database and depending on whether or not we are in
      # safe mode this will occur on the same thread or a different one.
      # (Subject to Rubinius stability and MRI's handling of threads.)
      #
      # @example Execute the insert command.
      #   insert.execute
      #
      # @return [ true, false ] If the operation succeeded.
      #
      # @since 2.1.0
      def execute
        consumer = Threaded.insert
        if consumer
          consumer.consume(documents, options)
        else
          master.insert(documents, options)
        end
      end
    end
  end
end
