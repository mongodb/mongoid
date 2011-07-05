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
      # @example Remove the document.
      #   Remove.persist
      #
      # @return [ true ] Always true.
      def persist
        if document.embedded?
          RemoveEmbedded.new(
            document,
            options.merge!(:validate => validating?, :suppress => !notifying_parent?)
          ).persist
        else
          collection.remove({ :_id => document.id }, options)
        end
        return true
      end
    end
  end
end
