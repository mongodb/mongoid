# frozen_string_literal: true

module Mongoid
  class Changeset
    # Immutable value object representing a single staged database operation.
    # Created at the moment an operation is staged (when save/destroy is called
    # and validation passes, or when a criteria-level op is invoked).
    #
    # For :insert entries, payload is the full serialized document.
    # For :update entries, payload is the result of atomic_updates() at save time.
    # For :delete entries, payload is nil.
    # For :update_many/:delete_many entries, document is nil.
    Entry = Struct.new(
      :type,        # Symbol: :insert | :update | :delete | :update_many | :delete_many
      :collection,  # Mongo::Collection
      :selector,    # Hash - MongoDB filter
      :payload,     # Hash | nil
      :document,    # Mongoid::Document | nil (nil for criteria-level entries)
      :session,     # Mongo::Session | nil
      keyword_init: true
    )
  end
end
