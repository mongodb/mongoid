# frozen_string_literal: true

module Mongoid
  module Clients
    module Options
      extend ActiveSupport::Concern

      # Change the persistence context for this object. Optionally provide a
      # block to demarcate when the persistence context should be cleared.
      #
      # @example Save the current document to a different collection.
      #   model.with(collection: "bands") do |m|
      #     m.save
      #   end
      #
      # @example Retrieve a document from a different collection.
      #   criteria = crit.with(collection: "bands")
      #   criteria.first
      #
      # @param [ Hash | Mongoid::PersistenceContext ] options_or_context
      #   The storage options or a persistence context.
      #
      # @option options [ String | Symbol ] :collection The collection name.
      # @option options [ String | Symbol ] :database The database name.
      # @option options [ String | Symbol ] :client The client name.
      #
      # @return [ self | Object ] The result of the block, if one is provided,
      #   or self.
      #
      # @raises [ Mongoid::Errors::UnsupportedWith ] when this method is called
      #   on a document instance.
      def with(options_or_context, &block)
        original_context = PersistenceContext.get(self)
        original_cluster = persistence_context.cluster
        if block_given?
          begin
            set_persistence_context(options_or_context)
            yield self
          ensure
            clear_persistence_context(original_cluster, original_context)
          end
        else
          # If #with is called on a Criteria we want to return a new criteria,
          # but if it's called on a document, we want to return the same document
          # since duping a document changes its _id.
          if is_a?(Criteria)
            dup.with!(options_or_context)
          else
            raise Mongoid::Errors::UnsupportedWith.new
          end
        end
      end

      # Change the persistence context for this object. This method modifies
      # the caller, and, unlike #with, does not accept a block.
      #
      # @example Save the current document to a different collection.
      #   band.with!(collection: "bands")
      #   band.save!

      # @example Retrieve a document from a different collection.
      #   criteria.with!(collection: "bands")
      #   criteria.first
      #
      # @param [ Hash | Mongoid::PersistenceContext ] options_or_context
      #   The storage options or a persistence context.
      #
      # @option options [ String | Symbol ] :collection The collection name.
      # @option options [ String | Symbol ] :database The database name.
      # @option options [ String | Symbol ] :client The client name.
      #
      # @return [ self ] returns self.
      def with!(options_or_context)
        @original_context = PersistenceContext.get(self)
        @original_cluster = persistence_context.cluster
        set_persistence_context(options_or_context)
        self
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

      # Returns the current persistence context or a new one constructed with
      # self.
      #
      # @return [ Mongoid::PersistenceContext ] the persistence context.
      def persistence_context
        PersistenceContext.get(self) ||
            PersistenceContext.get(self.class) ||
            PersistenceContext.new(self.class)
      end

      # Was a persistence context set?
      #
      # @return [ true | false ] true if a persistence context was set,
      #   false otherwise.
      def persistence_context?
        !!(PersistenceContext.get(self) || PersistenceContext.get(self.class))
      end

      def clear_persistence_context!
        clear_persistence_context(@original_cluster, @original_context)
      end

      private

      def set_persistence_context(options_or_context)
        PersistenceContext.set(self, options_or_context)
      end

      def clear_persistence_context(original_cluster = nil, context = nil)
        PersistenceContext.clear(self, original_cluster, context)
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

        # Change the persistence context for this class. Optionally provide a
        # block to demarcate when the persistence context should be cleared.
        #
        # @example Save the current document to a different collection.
        #   Model.with(collection: "bands") do |m|
        #     m.create!
        #   end
        #
        # @example Retrieve a document from a different collection.
        #   criteria = Model.with(collection: "bands")
        #   criteria.first
        #
        # @param [ Hash | Mongoid::PersistenceContext ] options_or_context
        #   The storage options or a persistence context.
        #
        # @option options [ String | Symbol ] :collection The collection name.
        # @option options [ String | Symbol ] :database The database name.
        # @option options [ String | Symbol ] :client The client name.
        #
        # @return [ Criteria | Object ] The result of the block, if one is provided,
        #   or a criteria with the given persistence context.
        def with(options_or_context, &block)
          original_context = PersistenceContext.get(self)
          original_cluster = persistence_context.cluster
          if block_given?
            begin
              set_persistence_context(options_or_context)
              yield self
            ensure
              clear_persistence_context(original_cluster, original_context)
            end
          else
            crit = criteria
            crit.send(:set_persistence_context, options_or_context)
            crit
          end
        end

        # Returns the current persistence context or a new one constructed with
        # self.
        #
        # @return [ Mongoid::PersistenceContext ] the persistence context.
        def persistence_context
          PersistenceContext.get(self) || PersistenceContext.new(self)
        end

        # Was a persistence context set?
        #
        # @return [ true | false ] true if a persistence context was set,
        #   false otherwise.
        def persistence_context?
          !!PersistenceContext.get(self)
        end

        private

        def set_persistence_context(options_or_context)
          PersistenceContext.set(self, options_or_context)
        end

        def clear_persistence_context(original_cluster = nil, context = nil)
          PersistenceContext.clear(self, original_cluster, context)
        end
      end
    end
  end
end
