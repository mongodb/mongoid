# encoding: utf-8
module Mongoid
  module Persistence
    module Operations
      module Embedded

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
          include Deletion
          include Operations
          include Mongoid::Atomic::Positionable

          # Remove the document from the database. If the parent is a new record,
          # it will get removed in Ruby only. If the parent is not a new record
          # then either an $unset or $set will occur, depending if it's an
          # embeds_one or embeds_many.
          #
          # @example Remove an embedded document.
          #   RemoveEmbedded.persist
          #
          # @return [ true ] Always true.
          def persist
            prepare do |doc|
              parent.remove_child(doc) if notifying_parent?
              if parent.persisted?
                selector = parent.atomic_selector
                collection.find(selector).update(positionally(selector, deletes))
              end
            end
          end
        end
      end
    end
  end
end
