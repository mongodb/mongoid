# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:
    # Insert is a persistence command responsible for taking a document that
    # has not been saved to the database and saving it.
    #
    # The underlying query resembles the following MongoDB query:
    #
    #   collection.insert(
    #     { "_id" : 1, "field" : "value" },
    #     false
    #   );
    class Insert < Command
      # Insert the new document in the database. This delegates to the standard
      # MongoDB collection's insert command.
      #
      # Example:
      #
      # <tt>Insert.persist</tt>
      #
      # Returns:
      #
      # The +Document+, whether the insert succeeded or not.
      def persist
        return @document if @validate && !@document.valid?
        @document.run_callbacks(:create) do
          @document.run_callbacks(:save) do
            if insert
              @document.persisted!
              @document.move_changes
            end
            @document
          end
        end
      end

      protected
      # Insert the document into the database.
      def insert
        if @document.embedded?
          Persistence::InsertEmbedded.new(@document, @validate).persist
        else
          @collection.insert(@document.raw_attributes, @options)
        end
      end
    end
  end
end
