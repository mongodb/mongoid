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
      # Example:
      #
      # <tt>RemoveEmbedded.persist</tt>
      #
      # Returns:
      #
      # +true+ or +false+, depending on if the removal passed.
      def persist
        parent = document._parent
        parent.remove_child(document)
        unless parent.new_record?
          update = { document._remover => removal_selector }
          collection.update(parent._selector, update, options.merge(:multi => false))
        end; true
      end

      protected
      # Get the value to pass to the removal modifier.
      def setter
        document._index ? document.id : true
      end

      def removal_selector
        document._index ? { document._pull => { "_id" => document.id } } : { document._path => setter }
      end
    end
  end
end
