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
      # @example Insert the document.
      #   Insert.persist
      #
      # @return [ Document ] The document to be inserted.
      def persist
        return document if validate && document.invalid?(:create)
        document.tap do |doc|
          doc.run_callbacks(:save) do
            doc.run_callbacks(:create) do
              if insert
                doc.new_record = false
                doc._children.each { |child| child.new_record = false }
                doc.move_changes
              end
            end
          end
        end
      end

      protected

      # Insert the document into the database.
      #
      # @example Insert the document.
      #   insert.insert
      #
      # @return [ true, false ] If the insert succeeded.
      def insert
        if document.embedded?
          Persistence::InsertEmbedded.new(
            document,
            options.merge(:validate => validate)
          ).persist
        else
          collection.insert(document.as_document, options)
        end
      end
    end
  end
end
