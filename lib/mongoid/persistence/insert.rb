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
    class Insert
      include Persistence::Command

      # Create the new insert persister.
      #
      # Options:
      #
      # document: The +Document+ to persist.
      # validate: +Boolean+ to validate or not.
      #
      # Example:
      #
      # <tt>Insert.new(document)</tt>
      def initialize(document, validate = true)
        init(document, validate)
        @options = { :safe => Mongoid.persist_in_safe_mode }
      end

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
        return @document if validate && !@document.valid?
        @document.run_callbacks(:create, :save) do
          @document.new_record = false if insert
          @document
        end
      end

      protected
      # Insert the document into the database.
      def insert
        collection.insert(@document.raw_attributes, options)
      end
    end
  end
end
