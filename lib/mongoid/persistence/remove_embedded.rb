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
    class RemoveEmbedded < Command

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
        true.tap do
          parent = document._parent
          parent.remove_child(document) unless suppress?
          unless parent.new_record?
            update = { document._remover => removal_selector }
            collection.update(parent._selector, update, options.merge(:multi => false))
          end
        end
      end

      protected

      # Get the value to pass to the removal modifier.
      #
      # @example Get the setter.
      #   command.setter
      #
      # @return [ BSON::ObjectId, true ] The id or true.
      def setter
        document._index ? document.id : true
      end

      # Get the removal selector.
      #
      # @example Get the selector.
      #   command.removal_selector
      #
      # @return [ Hash ] The removal selector.
      def removal_selector
        if document._index
          { document._pull => { "_id" => document.id } }
        else
          { document._path => setter }
        end
      end
    end
  end
end
