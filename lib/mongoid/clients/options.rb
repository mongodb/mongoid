# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module Clients

    # Mixin module included into Mongoid::Document which gives
    # the ability to manage the database context for persistence
    # and query operations. For example, this includes saving
    # documents to different collections, and reading documents
    # from secondary instances.
    module Options
      extend ActiveSupport::Concern

      # Change the persistence context for this object during the block.
      #
      # @example Save the current document to a different collection.
      #   model.with(collection: "bands") do |m|
      #     m.save
      #   end
      #
      # @param [ Hash | Mongoid::PersistenceContext ] options_or_context
      #   The storage options or a persistence context.
      #
      # @option options [ String | Symbol ] :collection The collection name.
      # @option options [ String | Symbol ] :database The database name.
      # @option options [ String | Symbol ] :client The client name.
      def with(options_or_context, &block)
        original_context = PersistenceContext.get(self)
        original_cluster = persistence_context.cluster
        set_persistence_context(options_or_context)
        yield self
      ensure
        clear_persistence_context(original_cluster, original_context)
      end

      # Get the collection for the document's current persistence context.
      #
      # @example Get the collection for the current persistence context.
      #   document.collection
      #
      # @param [ Object ] parent The parent object whose collection name is used
      #   instead of the current persistence context's collection name.
      #
      # @return [ Mongo::Collection ] The collection for the current persistence
      #   context.
      def collection(parent = nil)
        persistence_context.collection(parent)
      end

      # Get the collection name for the document's current persistence context.
      #
      # @example Get the collection name for the current persistence context.
      #   document.collection_name
      #
      # @return [ String ] The collection name for the current persistence
      #   context.
      def collection_name
        persistence_context.collection_name
      end

      # Get the database client for the document's current persistence context.
      #
      # @example Get the client for the current persistence context.
      #   document.mongo_client
      #
      # @return [ Mongo::Client ] The client for the current persistence
      #   context.
      def mongo_client
        persistence_context.client
      end

      # Get the document's current persistence context.
      #
      # @note For embedded documents, the persistence context of the
      #   root parent document is returned.
      #
      # @example Get the current persistence context.
      #   document.persistence_context
      #
      # @return [ Mongoid::PersistenceContext ] The current persistence
      #   context.
      def persistence_context
        if embedded? && !_root?
          _root.persistence_context
        else
          PersistenceContext.get(self) ||
            PersistenceContext.get(self.class) ||
            PersistenceContext.new(self.class, storage_options)
        end
      end

      # Returns whether a persistence context is set for the document
      # or the document's class.
      #
      # @note For embedded documents, the persistence context of the
      #   root parent document is used.
      #
      # @example Get the current persistence context.
      #   document.persistence_context?
      #
      # @return [ true | false ] Whether a persistence context is set.
      def persistence_context?
        if embedded? && !_root?
          _root.persistence_context?
        else
          remembered_storage_options&.any? ||
            PersistenceContext.get(self).present? ||
            PersistenceContext.get(self.class).present?
        end
      end

      private

      def set_persistence_context(options_or_context)
        PersistenceContext.set(self, options_or_context)
      end

      def clear_persistence_context(original_cluster = nil, context = nil)
        PersistenceContext.clear(self, original_cluster, context)
      end

      module ClassMethods

        # Get the database client name for the current persistence context
        # of the document class.
        #
        # @example Get the client name for the current persistence context.
        #   Model.client_name
        #
        # @return [ String ] The database client name for the current
        #   persistence context.
        def client_name
          persistence_context.client_name
        end

        # Get the collection name for the current persistence context of the
        # document class.
        #
        # @example Get the collection name for the current persistence context.
        #   Model.collection_name
        #
        # @return [ String ] The collection name for the current persistence
        #   context.
        def collection_name
          persistence_context.collection_name
        end

        # Get the database name for the current persistence context of the
        # document class.
        #
        # @example Get the database name for the current persistence context.
        #   Model.database_name
        #
        # @return [ String ] The database name for the current persistence
        #   context.
        def database_name
          persistence_context.database_name
        end

        # Get the collection for the current persistence context of the
        # document class.
        #
        # @example Get the collection for the current persistence context.
        #   Model.collection
        #
        # @return [ Mongo::Collection ] The collection for the current
        #   persistence context.
        def collection
          persistence_context.collection
        end

        # Get the client for the current persistence context of the
        # document class.
        #
        # @example Get the client for the current persistence context.
        #   Model.mongo_client
        #
        # @return [ Mongo::Client ] The client for the current persistence
        #   context.
        def mongo_client
          persistence_context.client
        end

        # Change the persistence context for this class during the block.
        #
        # @example Save the current document to a different collection.
        #   Model.with(collection: "bands") do |m|
        #     m.create
        #   end
        #
        # @param [ Hash ] options The storage options.
        #
        # @option options [ String | Symbol ] :collection The collection name.
        # @option options [ String | Symbol ] :database The database name.
        # @option options [ String | Symbol ] :client The client name.
        def with(options, &block)
          original_context = PersistenceContext.get(self)
          original_cluster = persistence_context.cluster
          PersistenceContext.set(self, options)
          yield self
        ensure
          PersistenceContext.clear(self, original_cluster, original_context)
        end

        # Get the current persistence context of the document class.
        # If a persistence context is not set, a new one will be
        # initialized and returned.
        #
        # @example Get the current persistence context.
        #   Model.persistence_context
        #
        # @return [ Mongoid::PersistenceContent ] The current persistence
        #   context.
        def persistence_context
          PersistenceContext.get(self) || PersistenceContext.new(self)
        end
      end
    end
  end
end
