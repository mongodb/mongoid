# encoding: utf-8
module Mongoid #:nodoc:
  module Collections #:nodoc:
    class Writer
      attr_reader :collection

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
        :update, :to => :collection

      # Create the new database writer. Will create a collection from the
      # master database.
      #
      # Example:
      #
      # <tt>Writer.new(master, "mongoid_people")</tt>
      def initialize(master_db, name)
        @collection = master_db.collection(name)
      end
    end
  end
end
