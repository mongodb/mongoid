# encoding: utf-8
module Mongoid
  module Persistence
    module Operations

      # Remove is a persistence command responsible for deleting a document from
      # the database.
      #
      # The underlying query resembles the following MongoDB query:
      #
      #   collection.remove(
      #     { "_id" : 1 },
      #     false
      #   );
      class Remove
        include Deletion, Operations

        # Remove the document from the database: delegates to the MongoDB
        # collection remove method.
        #
        # @example Remove the document.
        #   Remove.persist
        #
        # @return [ true ] Always true.
        def persist
          prepare do |doc|
            collection.find(doc.atomic_selector).remove
          end
        end
      end
    end
  end
end
