# encoding: utf-8
module Mongoid #:nodoc:
  module Collections #:nodoc:
    class Reader

      attr_reader :iterator

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
        :options,
        :size, :to => :collection

      # Create the new database reader. Will create a collection from the
      # slave databases and cycle through them on each read.
      #
      # Example:
      #
      # <tt>Reader.new(slaves, "mongoid_people")</tt>
      def initialize(slaves, name)
        @iterator = CyclicIterator.new(
          slaves.collect { |db| db.collection(name) }
        )
      end

      protected
      def collection
        @iterator.next
      end
    end
  end
end
