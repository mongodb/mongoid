# frozen_string_literal: true

module Mongoid

  # A cache of database queries on a per-request basis.
  module QueryCache

    class << self

      # Clear the query cache.
      #
      # @example Clear the cache.
      #   QueryCache.clear_cache
      #
      # @return [ nil ] Always nil.
      def clear_cache
        Mongoid::Warnings.warn_mongoid_query_cache_clear
        Mongo::QueryCache.clear
      end

      # Set whether the cache is enabled.
      #
      # @example Set if the cache is enabled.
      #   QueryCache.enabled = true
      #
      # @param [ true | false ] value The enabled value.
      def enabled=(value)
        Mongoid::Warnings.warn_mongoid_query_cache
        Mongo::QueryCache.enabled = value
      end

      # Is the query cache enabled on the current thread?
      #
      # @example Is the query cache enabled?
      #   QueryCache.enabled?
      #
      # @return [ true | false ] If the cache is enabled.
      def enabled?
        Mongoid::Warnings.warn_mongoid_query_cache
        Mongo::QueryCache.enabled?
      end

      # Execute the block while using the query cache.
      #
      # @example Execute with the cache.
      #   QueryCache.cache { collection.find }
      #
      # @return [ Object ] The result of the block.
      def cache(&block)
        Mongoid::Warnings.warn_mongoid_query_cache
        Mongo::QueryCache.cache(&block)
      end

      # Execute the block with the query cache disabled.
      #
      # @example Execute without the cache.
      #   QueryCache.uncached { collection.find }
      #
      # @return [ Object ] The result of the block.
      def uncached(&block)
        Mongoid::Warnings.warn_mongoid_query_cache
        Mongo::QueryCache.uncached(&block)
      end
    end

    Middleware = Mongo::QueryCache::Middleware
  end
end
