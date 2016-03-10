# encoding: utf-8
module Mongoid
  module Clients
    module Options
      extend ActiveSupport::Concern

      # Change the persistence context for this object during the block.
      #
      # @example Save the current document to a different collection.
      #   model.with(collection: "secondary") do |m|
      #     m.save
      #   end
      #
      # @param [ Hash ] options The storage options.
      #
      # @option options [ String, Symbol ] :collection The collection name.
      # @option options [ String, Symbol ] :database The database name.
      # @option options [ String, Symbol ] :client The client name.
      #
      # @since 6.0.0
      def with(options, &block)
        original_cluster = persistence_context.cluster
        set_persistence_context(options)
        yield self
      ensure
        # @todo: test that this is cleared upon error
        clear_persistence_context(original_cluster)
      end

      def collection(parent = nil)
        persistence_context.collection(parent)
      end

      def collection_name
        persistence_context.collection_name
      end

      def mongo_client
        persistence_context.client
      end

      def persistence_context
        PersistenceContext.get(self) ||
            PersistenceContext.get(self.class) ||
            PersistenceContext.new(self.class)
      end

      private

      def set_persistence_context(options)
        PersistenceContext.set(self, options)
      end

      def clear_persistence_context(original_cluster)
        PersistenceContext.clear(self, original_cluster)
      end

      module ClassMethods

        def client_name
          persistence_context.client_name
        end

        def collection_name
          persistence_context.collection_name
        end

        def database_name
          persistence_context.database_name
        end

        def collection
          persistence_context.collection
        end

        def mongo_client
          persistence_context.client
        end

        # Change the persistence context for this class during the block.
        #
        # @example Save the current document to a different collection.
        #   Model.with(collection: "secondary") do |m|
        #     m.create
        #   end
        #
        # @param [ Hash ] options The storage options.
        #
        # @option options [ String, Symbol ] :collection The collection name.
        # @option options [ String, Symbol ] :database The database name.
        # @option options [ String, Symbol ] :client The client name.
        #
        # @since 6.0.0
        def with(options, &block)
          original_cluster = persistence_context.cluster
          PersistenceContext.set(self, options)
          yield self
        ensure
          # @todo: test that this is cleared upon error
          PersistenceContext.clear(self, original_cluster)
        end

        def persistence_context
          PersistenceContext.get(self) || PersistenceContext.new(self)
        end
      end
    end
  end
end
