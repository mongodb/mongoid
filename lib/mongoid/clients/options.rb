# frozen_string_literal: true
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
      # @param [ Hash, Mongoid::PersistenceContext ] options_or_context
      #   The storage options or a persistence context.
      #
      # @option options [ String, Symbol ] :collection The collection name.
      # @option options [ String, Symbol ] :database The database name.
      # @option options [ String, Symbol ] :client The client name.
      #
      # @since 6.0.0
      def with(options_or_context, &block)
        # Only changing the collection name does not require the overhead of an entire new persistence context.
        if options_or_context.is_a?(Hash) && (options_or_context.size == 1) && options_or_context.key?(:collection)
          self.collection_name = options_or_context[:collection]
          return block_given? ? yield(self) : self
        end

        original_cluster = persistence_context.cluster
        set_persistence_context(options_or_context)
        yield self
      ensure
        clear_persistence_context(original_cluster)
      end

      def collection(parent = nil)
        @collection_name ? mongo_client[@collection_name] : persistence_context.collection(parent)
      end

      def collection_name
        @collection_name || persistence_context.collection_name
      end

      def collection_name=(collection_name)
        @collection_name = collection_name.nil? ? nil : collection_name.to_sym
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

      def set_persistence_context(options_or_context)
        PersistenceContext.set(self, options_or_context)
      end

      def clear_persistence_context(original_cluster = nil)
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
          # Support changing just the collection name, when not used with a block
          if !block_given? && options.is_a?(Hash) && (options.size == 1) && options.key?(:collection)
            return all.with(options, &block)
          end

          begin
            original_cluster = persistence_context.cluster
            PersistenceContext.set(self, options)
            yield self
          ensure
            PersistenceContext.clear(self, original_cluster)
          end
        end

        def persistence_context
          PersistenceContext.get(self) || PersistenceContext.new(self)
        end
      end
    end
  end
end
