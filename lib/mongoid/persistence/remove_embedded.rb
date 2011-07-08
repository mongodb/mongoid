# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:

    # Remove is a persistence command responsible for deleting a document from
    # the database.
    #
    # The underlying query resembles the following MongoDB query:
    #
    #   collection.remove(
    #     { "_id" : 1 },
    #     false
    #   );
    class RemoveEmbedded
      include Operations

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
        parent = document._parent
        parent.remove_child(document) if notifying_parent?
        unless parent.new_record?
          update = { document.atomic_delete_modifier => removal_selector }
          collection.update(parent.atomic_selector, update, options)
        end
        return true
      end

      protected

      # Get the removal selector.
      #
      # @example Get the selector.
      #   command.removal_selector
      #
      # @return [ Hash ] The removal selector.
      def removal_selector
        if document._index
          { document.atomic_path => { "_id" => document.id } }
        else
          { document.atomic_path => true }
        end
      end
    end
  end
end
