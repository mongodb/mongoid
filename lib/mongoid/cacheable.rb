# frozen_string_literal: true

module Mongoid

  # Encapsulates behavior around caching.
  module Cacheable
    extend ActiveSupport::Concern

    included do
      cattr_accessor :cache_timestamp_format, instance_writer: false
      self.cache_timestamp_format = :nsec
    end

    # Print out the cache key. This will append different values on the
    # plural model name.
    #
    # If new_record?     - will append /new
    # If not             - will append /id-updated_at.to_formatted_s(cache_timestamp_format)
    # Without updated_at - will append /id
    #
    # This is usually called inside a cache() block
    #
    # @example Returns the cache key
    #   document.cache_key
    #
    # @return [ String ] the string with or without updated_at
    def cache_key
      return "#{model_key}/new" if new_record?
      return "#{model_key}/#{_id}-#{updated_at.utc.to_formatted_s(cache_timestamp_format)}" if do_or_do_not(:updated_at)
      "#{model_key}/#{_id}"
    end
  end
end
