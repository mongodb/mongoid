# frozen_string_literal: true

require 'concurrent/map'

module Mongoid
  module Attributes
    # Caching accessor for attribute reading and writing.
    # This accessor caches demongoized values for performance.
    #
    # Each instance maintains its own cache (Concurrent::Map), so each document
    # that uses caching gets a unique CachingAccessor instance to avoid sharing
    # cached values across documents.
    #
    # @api private
    class CachingAccessor < Accessor
      def initialize
        super
        @demongoized_cache = Concurrent::Map.new
      end

      # Read an attribute value from a document with caching.
      #
      # @param [ Document ] document The document to read from.
      # @param [ String | Symbol ] field_name The name of the field.
      # @param [ Fields::Standard ] field The field definition.
      #
      # @return [ Object ] The demongoized attribute value.
      def read(document, field_name, field)
        # Fast paths - no caching for special cases
        # If field is nil, process raw attribute directly (dynamic fields)
        if field.nil?
          return document.process_raw_attribute(field_name.to_s, document.send(:read_raw_attribute, field_name),
                                                nil)
        end
        return super if field.localized?

        # Atomically fetch or compute and cache the demongoized value
        @demongoized_cache.fetch_or_store(field_name) do
          raw = document.send(:read_raw_attribute, field_name)

          if lazy_settable?(document, field, raw)
            evaluate_default(document, field_name, field, raw)
          else
            document.process_raw_attribute(field_name.to_s, raw, field)
          end
        end
      end

      # Invalidate the cached value for the given field.
      #
      # @param [ String | Symbol ] field_name The name of the field.
      def invalidate(field_name)
        @demongoized_cache.delete(field_name)
      end

      # Reset all cached values.
      def reset!
        @demongoized_cache.clear
      end

      private

      # Evaluate and set the default value for a lazy field.
      #
      # This method handles a subtle interaction with the cache:
      # 1. fetch_or_store (line 38) executes this block
      # 2. write_attribute invalidates the cache for this field
      # 3. We re-read the raw value and demongoize it
      # 4. fetch_or_store caches the returned demongoized value
      #
      # This ensures lazy-settable fields are properly cached after
      # their default value is evaluated and written.
      #
      # @param [ Document ] document The document.
      # @param [ String | Symbol ] field_name The field name.
      # @param [ Fields::Standard ] field The field definition.
      # @param [ Object ] raw The raw value.
      #
      # @return [ Object ] The demongoized default value.
      def evaluate_default(document, field_name, field, _raw)
        document.write_attribute(field_name, field.eval_default(document))
        # Re-read to get the demongoized value (write_attribute stores mongoized value)
        document.process_raw_attribute(field_name.to_s, document.send(:read_raw_attribute, field_name), field)
      end
    end
  end
end
