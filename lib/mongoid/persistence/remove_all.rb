# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:

    # Remove is a persistence command responsible for deleting a document from
    # the database.
    #
    # The underlying query resembles the following MongoDB query:
    #
    #   collection.remove(
    #     { "field" : value },
    #     false
    #   );
    class RemoveAll < Command

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
        select = (klass.hereditary? ? selector.merge(:_type => klass.name) : selector)
        collection.find(select).count.tap do
          collection.remove(select, options)
        end
      end
    end
  end
end
