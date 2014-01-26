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

    module Base # :nodoc:

      def alias_query_cache_clear(*method_names)
        method_names.each do |method_name|
          class_eval <<-CODE, __FILE__, __LINE__ + 1
              def #{method_name}_with_clear_cache(*args)
                QueryCache.clear_cache
                #{method_name}_without_clear_cache(*args)
              end
            CODE

          alias_method_chain method_name, :clear_cache
        end
      end
    end

    module Query # :nodoc:
      def self.included(base)
        base.extend QueryCache::Base
        base.alias_method_chain(:cursor, :cache)
        base.alias_query_cache_clear(:remove, :remove_all, :update, :update_all, :upsert)
      end

      def cursor_with_cache
        CachedCursor.new(session, operation)
      end
    end

    module Collection # :nodoc:
      def self.included(base)
        base.extend QueryCache::Base
        base.alias_query_cache_clear(:insert)
      end
    end

    class CachedCursor < Moped::Cursor # :nodoc:

      def load_docs
        with_cache { super }
      end

      private
      def with_cache
        return yield unless QueryCache.enabled?
        return yield if @collection =~ /^system./
        key = [@database, @collection, @selector]
        if QueryCache.cache_table.has_key? key
          instrument(key) { QueryCache.cache_table[key] }
        else
          QueryCache.cache_table[key] = yield
        end
      end

      def instrument(key, &block)
        ActiveSupport::Notifications.instrument("query_cache.mongoid", key: key, &block)
      end
    end
  end
end

Moped::Query.__send__(:include, Mongoid::QueryCache::Query)
Moped::Collection.__send__(:include, Mongoid::QueryCache::Collection)
