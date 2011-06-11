# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:

    # Insert is a persistence command responsible for taking a document that
    # has not been saved to the database and saving it. This specific class
    # handles the case when the document is embedded in another.
    #
    # The underlying query resembles the following MongoDB query:
    #
    #   collection.insert(
    #     { "_id" : 1, "field" : "value" },
    #     false
    #   );
    class InsertEmbedded < Command

      # Insert the new document in the database. If the document's parent is a
      # new record, we will call save on the parent, otherwise we will $push
      # the document onto the parent.
      #
      # @example Insert an embedded document.
      #   Insert.persist
      #
      # @return [ Document ] The document to be inserted.
      def persist
        return document if validate && document.invalid?(:create)
        document.tap do |doc|
          parent = doc._parent
          if parent.new_record?
            parent.insert
          else
            update = { doc._inserter => { doc._position => doc.as_document } }
            collection.update(parent._selector, update, options.merge(:multi => false))
            doc.new_record = false
            doc.move_changes
          end
        end
      end
    end
  end
end
