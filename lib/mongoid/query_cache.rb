# frozen_string_literal: true
# encoding: utf-8

module Mongoid

  # A cache of database queries on a per-request basis.
  #
  # @since 4.0.0
  module QueryCache
    class << self

      # Get the cached queries.
      #
      # @example Get the cached queries from the current thread.
      #   QueryCache.cache_table
      #
      # @return [ Hash ] The hash of cached queries.
      #
      # @since 4.0.0
      def cache_table
        Thread.current["[mongoid]:query_cache"] ||= {}
      end

      # Clear the query cache.
      #
      # @example Clear the cache.
      #   QueryCache.clear_cache
      #
      # @return [ nil ] Always nil.
      #
      # @since 4.0.0
      def clear_cache
        Thread.current["[mongoid]:query_cache"] = nil
      end

      # Set whether the cache is enabled.
      #
      # @example Set if the cache is enabled.
      #   QueryCache.enabled = true
      #
      # @param [ true, false ] value The enabled value.
      #
      # @since 4.0.0
      def enabled=(value)
        Thread.current["[mongoid]:query_cache:enabled"] = value
      end

      # Is the query cache enabled on the current thread?
      #
      # @example Is the query cache enabled?
      #   QueryCache.enabled?
      #
      # @return [ true, false ] If the cache is enabled.
      #
      # @since 4.0.0
      def enabled?
        !!Thread.current["[mongoid]:query_cache:enabled"]
      end

      # Execute the block while using the query cache.
      #
      # @example Execute with the cache.
      #   QueryCache.cache { collection.find }
      #
      # @return [ Object ] The result of the block.
      #
      # @since 4.0.0
      def cache
        enabled = QueryCache.enabled?
        QueryCache.enabled = true
        yield
      ensure
        QueryCache.enabled = enabled
      end

      # Execute the block with the query cache disabled.
      #
      # @example Execute without the cache.
      #   QueryCache.uncached { collection.find }
      #
      # @return [ Object ] The result of the block.
      def uncached
        enabled = QueryCache.enabled?
        QueryCache.enabled = false
        yield
      ensure
        QueryCache.enabled = enabled
      end
    end

    # The middleware to be added to a rack application in order to activate the
    # query cache.
    #
    # @since 4.0.0
    class Middleware

      # Instantiate the middleware.
      #
      # @example Create the new middleware.
      #   Middleware.new(app)
      #
      # @param [ Object ] app The rack applciation stack.
      #
      # @since 4.0.0
      def initialize(app)
        @app = app
      end

      # Execute the request, wrapping in a query cache.
      #
      # @example Execute the request.
      #   middleware.call(env)
      #
      # @param [ Object ] env The environment.
      #
      # @return [ Object ] The result of the call.
      #
      # @since 4.0.0
      def call(env)
        QueryCache.cache { @app.call(env) }
      ensure
        QueryCache.clear_cache
      end
    end

    # A Cursor that attempts to load documents from memory first before hitting
    # the database if the same query has already been executed.
    #
    # @since 5.0.0
    class CachedCursor < Mongo::Cursor

      # We iterate over the cached documents if they exist already in the
      # cursor otherwise proceed as normal.
      #
      # @example Iterate over the documents.
      #   cursor.each do |doc|
      #     # ...
      #   end
      #
      # @since 5.0.0
      def each
        if @cached_documents
          @cached_documents.each do |doc|
            yield doc
          end
        else
          super
        end
      end

      # Get a human-readable string representation of +Cursor+.
      #
      # @example Inspect the cursor.
      #   cursor.inspect
      #
      # @return [ String ] A string representation of a +Cursor+ instance.
      #
      # @since 2.0.0
      def inspect
        "#<Mongoid::QueryCache::CachedCursor:0x#{object_id} @view=#{@view.inspect}>"
      end

      private

      def process(result)
        @remaining -= result.returned_count if limited?
        @cursor_id = result.cursor_id
        @coll_name ||= result.namespace.sub("#{database.name}.", '') if result.namespace
        documents = result.documents
        if @cursor_id.zero? && !@after_first_batch
          @cached_documents ||= []
          @cached_documents.concat(documents)
        end
        @after_first_batch = true
        documents
      end
    end

    # Included to add behavior for clearing out the query cache on certain
    # operations.
    #
    # @since 4.0.0
    module Base

      def alias_query_cache_clear(*method_names)
        method_names.each do |method_name|
          define_method("#{method_name}_with_clear_cache") do |*args|
            QueryCache.clear_cache
            send("#{method_name}_without_clear_cache", *args)
          end

          alias_method "#{method_name}_without_clear_cache", method_name
          alias_method method_name, "#{method_name}_with_clear_cache"
        end
      end
    end

    # Contains enhancements to the Mongo::Collection::View in order to get a
    # cached cursor or a regular cursor on iteration.
    #
    # @since 5.0.0
    module View
      extend ActiveSupport::Concern

      included do
        extend QueryCache::Base
        alias_query_cache_clear :delete_one,
                                :delete_many,
                                :update_one,
                                :update_many,
                                :replace_one,
                                :find_one_and_delete,
                                :find_one_and_replace,
                                :find_one_and_update
      end

      # Override the default enumeration to handle if the cursor can be cached
      # or not.
      #
      # @example Iterate over the view.
      #   view.each do |doc|
      #     # ...
      #   end
      #
      # @since 5.0.0
      def each
        if system_collection? || !QueryCache.enabled?
          super
        else
          unless cursor = cached_cursor
            read_with_retry do
              server = server_selector.select_server(cluster)
              result = send_initial_query(server)
              if result.cursor_id == 0 || result.cursor_id.nil?
                cursor = CachedCursor.new(view, result, server)
                QueryCache.cache_table[cache_key] = cursor
              else
                cursor = Mongo::Cursor.new(view, result, server)
              end
            end
          end

          if block_given?
            if limit && limit != -1
              cursor.to_a[0...limit].each do |doc|
                yield doc
              end
            else
              cursor.each do |doc|
                yield doc
              end
            end
          else
            cursor
          end
        end
      end

      private

      def cached_cursor
        if limit
          key = [ collection.namespace, selector, nil, skip, sort, projection, collation  ]
          cursor = QueryCache.cache_table[key]
        end
        cursor || QueryCache.cache_table[cache_key]
      end

      def cache_key
        [ collection.namespace, selector, limit, skip, sort, projection, collation ]
      end

      def system_collection?
        collection.namespace =~ /\Asystem./
      end
    end

    # Adds behavior to the query cache for collections.
    #
    # @since 5.0.0
    module Collection
      extend ActiveSupport::Concern

      included do
        extend QueryCache::Base
        alias_query_cache_clear :insert_one, :insert_many
      end
    end

    # Bypass the query cache when reloading a document.
    module Document
      def reload
        QueryCache.uncached { super }
      end
    end
  end
end

Mongo::Collection.__send__(:include, Mongoid::QueryCache::Collection)
Mongo::Collection::View.__send__(:include, Mongoid::QueryCache::View)
Mongoid::Document.__send__(:include, Mongoid::QueryCache::Document)
