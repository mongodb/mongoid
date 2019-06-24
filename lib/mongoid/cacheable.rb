# frozen_string_literal: true
# encoding: utf-8

module Mongoid

  # Encapsulates behavior around caching.
  #
  # @since 6.0.0
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
      return "#{model_key}/new" if new_record?
      return "#{model_key}/#{id}-#{updated_at.utc.to_s(cache_timestamp_format)}" if do_or_do_not(:updated_at)
      "#{model_key}/#{id}"
    end
  end
end
