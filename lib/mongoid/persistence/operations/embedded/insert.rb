# encoding: utf-8
module Mongoid
  module Persistence
    module Operations
      module Embedded

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
        class Insert
          include Insertion
          include Operations
          include Mongoid::Atomic::Positionable

          # Insert the new document in the database. If the document's parent is a
          # new record, we will call save on the parent, otherwise we will $push
          # the document onto the parent.
          #
          # @example Insert an embedded document.
          #   Insert.persist
          #
          # @return [ Document ] The document to be inserted.
          def persist
            prepare do
              raise Errors::NoParent.new(document.class.name) unless parent
              if parent.new_record?
                parent.insert
              else
                selector = parent.atomic_selector
                collection.find(selector).update(positionally(selector, inserts))
              end
            end
          end
        end
      end
    end
  end
end
