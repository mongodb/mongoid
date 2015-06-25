# encoding: utf-8
module Mongoid

  # Provides behaviour for generating the selector for a specific document.
  #
  # @since 4.0.0
  module Selectable
    extend ActiveSupport::Concern

    # Get the atomic selector for the document. This is a hash in the simplest
    # case { "_id" => id }, but can become more complex for embedded documents
    # and documents that use a shard key.
    #
    # @example Get the document's atomic selector.
    #   document.atomic_selector
    #
    # @return [ Hash ] The document's selector.
    #
    # @since 1.0.0
    def atomic_selector
      @atomic_selector ||= { "_id" => _root._id }.merge!(shard_key_selector)
    end
  end
end
