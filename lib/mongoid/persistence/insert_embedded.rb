# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:

    # Insert is a persistence command responsible for taking a document that
    # has not been saved to the database and saving it. This specific class
    # handles the case when the document is embedded in another.
    #
    # The underlying query resembles the following MongoDB query:
    #
    #   collection.update(
    #     { "_id" : 1 },
    #     { "$push" : { "field" : "value" } },
    #     false
    #   );
    class InsertEmbedded
      include Insertion, Operations

      # Insert the new document in the database. If the document's parent is a
      # new record, we will call save on the parent, otherwise we will $push
      # the document onto the parent.
      #
      # @example Insert an embedded document.
      #   Insert.persist
      #
      # @return [ Document ] The document to be inserted.
      def persist
        insert do |doc|
          if parent.new?
            parent.insert
          else
            update = {
              doc.atomic_insert_modifier => { doc.atomic_position => doc.as_document }
            }
            collection.update(parent.atomic_selector, update, options)
          end
        end
      end
    end
  end
end
