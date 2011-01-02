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
    class Remove < Command

      # Remove the document from the database: delegates to the MongoDB
      # collection remove method.
      #
      # Example:
      #
      # <tt>Remove.persist</tt>
      #
      # Returns:
      #
      # +true+ if success, +false+ if not.
      def persist
        remove
      end

      protected
      # Remove the document from the database.
      def remove
        if document.embedded?
          Persistence::RemoveEmbedded.new(
            document,
            options.merge(:validate => validate)
          ).persist
        else
          collection.remove({ :_id => document.id }, options)
        end; true
      end
    end
  end
end
