# frozen_string_literal: true
# rubocop:todo all

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
    # If new_record? - will append /new
    # Non-nil cache_version? - append /id
    # Non-nil updated_at - append /id-updated_at.to_formatted_s(cache_timestamp_format)
    # Otherwise - append /id
    #
    # This is usually called inside a cache() block
    #
    # @example Returns the cache key
    #   document.cache_key
    #
    # @return [ String ] the generated cache key
    def cache_key
      return "#{model_key}/new" if new_record?
      return "#{model_key}/#{_id}" if cache_version
      return "#{model_key}/#{_id}-#{updated_at.utc.to_formatted_s(cache_timestamp_format)}" if try(:updated_at)
      "#{model_key}/#{_id}"
    end

    # Return the cache version for this model. By default, it returns the updated_at
    # field (if present) formatted as a string, or nil if the model has no
    # updated_at field. Models with different needs may override this method to
    # suit their desired behavior.
    #
    # @return [ String | nil ] the cache version value
    #
    # TODO: we can test this by using a MemoryStore, putting something in
    # it, then updating the timestamp on the record and trying to read the
    # value from the memory store. It shouldn't find it, because the version
    # has changed.
    def cache_version
      if has_attribute?('updated_at') && updated_at.present?
        updated_at.utc.to_formatted_s(cache_timestamp_format)
      end
    end
  end
end
