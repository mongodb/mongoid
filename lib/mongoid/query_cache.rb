# frozen_string_literal: true

module Mongoid

  # A cache of database queries on a per-request basis.
  #
  # The current implementation is a simple wrapper around the Mongo Ruby driver's
  # query cache. It is deprecated and will be removed in a future version of
  # Mongoid. Please use the Mongo Ruby driver's query cache instead.
  #
  # @deprecated
  module QueryCacheDeprecated
    class << self

      # Clear the query cache.
      #
      # @example Clear the cache.
      #   QueryCache.clear_cache
      #
      # @return [ nil ] Always nil.
      def clear_cache
        Mongo::QueryCache.clear
      end

      # Set whether the cache is enabled.
      #
      # @example Set if the cache is enabled.
      #   QueryCache.enabled = true
      #
      # @param [ true | false ] value The enabled value.
      def enabled=(value)
        Mongo::QueryCache.enabled = value
      end

      # Is the query cache enabled on the current thread?
      #
      # @example Is the query cache enabled?
      #   QueryCache.enabled?
      #
      # @return [ true | false ] If the cache is enabled.
      def enabled?
        Mongo::QueryCache.enabled?
      end

      # Execute the block while using the query cache.
      #
      # @example Execute with the cache.
      #   QueryCache.cache { collection.find }
      #
      # @return [ Object ] The result of the block.
      def cache(&block)
        Mongo::QueryCache.cache(&block)
      end

      # Execute the block with the query cache disabled.
      #
      # @example Execute without the cache.
      #   QueryCache.uncached { collection.find }
      #
      # @return [ Object ] The result of the block.
      def uncached(&block)
        Mongo::QueryCache.uncached(&block)
      end
    end

    # @deprecated
    Middleware = Mongo::QueryCache::Middleware
  end
end

Mongoid::QueryCache = Mongoid::Deprecation::DeprecatedConstantProxy.new(
  'Mongoid::QueryCacheDeprecated',
  'Mongoid::QueryCacheDeprecated',
  message: 'Mongoid::QueryCache is deprecated and will be removed in Mongoid 9.0. ' \
           'Please use Mongo::QueryCache instead.'
)
