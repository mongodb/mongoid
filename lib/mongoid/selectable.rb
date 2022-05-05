# frozen_string_literal: true

module Mongoid

  # Provides behavior for generating the selector for a specific document.
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
    def atomic_selector
      embedded? ? embedded_atomic_selector : root_atomic_selector_in_db
    end

    private

    # Get the atomic selector for an embedded document.
    #
    # @api private
    #
    # @example Get the embedded atomic selector.
    #   document.embedded_atomic_selector
    #
    # @return [ Hash ] The embedded document selector.
    def embedded_atomic_selector
      if persisted? && _id_changed?
        _parent.atomic_selector
      else
        _parent.atomic_selector.merge("#{atomic_path}._id" => _id)
      end
    end

    # Get the atomic selector that would match the existing version of the
    # root document.
    #
    # @api private
    #
    # @return [ Hash ] The root document selector.
    def root_atomic_selector_in_db
      { "_id" => _id }.merge!(shard_key_selector_in_db)
    end
  end
end
