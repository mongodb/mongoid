# frozen_string_literal: true

module Mongoid
  module Contextual
    module Cacheable

      # Is the context cached?
      #
      # @example Is the context cached?
      #   context.cached?
      #
      # @return [ true, false ] If the context is cached.
      def cached?
        !!@cache
      end

      # Is the cache fully loaded? Will be true if caching after one full
      # iteration.
      #
      # @api private
      #
      # @example Is the cache loaded?
      #   context.cache_loaded?
      #
      # @return [ true, false ] If the cache is loaded.
      def cache_loaded?
        !!@cache_loaded
      end

      # Is the cache able to be added to?
      #
      # @api private
      #
      # @example Is the context cacheable?
      #   context.cacheable?
      #
      # @return [ true, false ] If caching, and the cache isn't loaded.
      def cacheable?
        cached? && !cache_loaded?
      end

      def operation_cached?(options)
        cache_table.key?(cache_key(options))
      end

      def get_from_cache(options)
        cache_table[cache_key(options)]
      end

      private

      # Get the cached queries.
      #
      # @api private
      #
      # @return [ Hash ] The hash of cached queries.
      def cache_table
        @cache_table ||= {}
      end

      def cache_key(options)
        # Not making collection part of the cache key as you can't modify the
        # collection without using instance_variable_set.
        [ collection.namespace,
          options[:method],
          options.fetch(:selector, view.selector),
          options.fetch(:limit, view.limit),
          options.fetch(:skip, view.skip),
          options.fetch(:sort, view.sort),
          options.fetch(:projection, view.projection),
          options.fetch(:collation, view.send(:collation)),
        ]
      end

      # yield the block given or return the cached value
      #
      # @api private
      #
      # @param [ Hash ] key The options set for the given method
      #
      # @return the result of the block
      def try_cache(options, &block)
        unless cached?
          yield
        else
          # TODO: remove me
          if options.is_a?(Symbol)
            options = { method: options }
          end
          ckey = cache_key(options)
          unless ret = cache_table[ckey]
            ret = yield
            cache_table[ckey] = ret
          end
          ret
        end
      end

      # yield the block given or return the cached value
      #
      # @api private
      #
      # @param [ String, Symbol ] key The instance variable name
      # @param [ Integer | nil ] n The number of documents requested or nil
      #   if none is requested.
      #
      # @return [ Object ] The result of the block.
      def try_numbered_cache(key, n, &block)
        unless cached?
          yield if block_given?
        else
          len = n || 1
          ret = instance_variable_get("@#{key}")
          if !ret || ret.length < len
            instance_variable_set("@#{key}", ret = Array.wrap(yield))
          elsif !n
            ret.is_a?(Array) ? ret.first : ret
          elsif ret.length > len
            ret.first(n)
          else
            ret
          end
        end
      end
    end
  end
end
