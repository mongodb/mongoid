# encoding: utf-8
module Mongoid #:nodoc
  # The collections module is used for providing functionality around setting
  # up and updating collections.
  module Collections
    extend ActiveSupport::Concern
    included do
      cattr_accessor :_collection, :collection_name
      self.collection_name = self.name.collectionize

      delegate :collection, :db, :to => "self.class"
    end

    module ClassMethods #:nodoc:
      # Returns the collection associated with this +Document+. If the
      # document is embedded, there will be no collection associated
      # with it.
      #
      # Returns: <tt>Mongo::Collection</tt>
      def collection
        raise Errors::InvalidCollection.new(self) if embedded?
        self._collection || set_collection
        add_indexes; self._collection
      end

      # Return the database associated with this collection.
      #
      # Example:
      #
      # <tt>Person.db</tt>
      def db
        collection.db
      end

      # Macro for setting the collection name to store in.
      #
      # Example:
      #
      # <tt>Person.store_in :populdation</tt>
      def store_in(name)
        self.collection_name = name.to_s
        set_collection
      end

      protected
      def set_collection
        self._collection = Mongoid::Collection.new(self, self.collection_name)
      end
    end
  end
end
