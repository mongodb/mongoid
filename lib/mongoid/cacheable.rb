# encoding: utf-8
module Mongoid

  # Encapsulates behaviour around caching.
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
    # If not             - will append /id-updated_at.to_s(cache_timestamp_format)
    # Without updated_at - will append /id
    #
    # This is usually called insode a cache() block
    #
    # @example Returns the cache key
    #   document.cache_key
    #
    # @return [ String ] the string with or without updated_at
    #
    # @since 2.4.0
    def cache_key
      case
      when new_record
        "#{model_key}/new"
      when do_or_do_not(:updated_at)
        timestamp = updated_at.utc.to_s(cache_timestamp_format)
        "#{model_key}/#{id}-#{timestamp}"
      else
        "#{model_key}/#{id}"
      end
    end
  end
end
