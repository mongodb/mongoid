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
        true.tap do
          if document.embedded?
            Persistence::RemoveEmbedded.new(
              document,
              options.merge(:validate => validate, :suppress => suppress)
            ).persist
          else
            collection.remove({ :_id => document.id }, options)
          end
        end
      end
    end
  end
end
