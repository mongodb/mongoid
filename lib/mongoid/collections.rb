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
      # with it unless it's in a cyclic relation.
      #
      # @example Get the collection.
      #   Model.collection
      #
      # @return [ Collection ] The Mongoid collection wrapper.
      def collection
        raise Errors::InvalidCollection.new(self) if embedded? && !cyclic
        self._collection || set_collection
        add_indexes; self._collection
      end

      # Return the database associated with this collection.
      #
      # @example Get the database object.
      #   Model.db
      #
      # @return [ Mongo::DB ] The Mongo daatabase object.
      def db
        collection.db
      end

      # Convenience method for getting index information from the collection.
      #
      # @example Get the index information from the collection.
      #   Model.index_information
      #
      # @return [ Array ] The collection index information.
      def index_information
        collection.index_information
      end

      # Macro for setting the collection name to store in.
      #
      # @example Store in a separate collection than the default.
      #   Model.store_in :population
      def store_in(name)
        self.collection_name = name.to_s
        set_collection
      end

      protected

      # Set the collection on the class.
      #
      # @example Set the collection.
      #   Model.set_collection
      #
      # @return [ Collection ] The Mongoid collection wrapper.
      def set_collection
        self._collection = Mongoid::Collection.new(self, self.collection_name)
      end
    end
  end
end
