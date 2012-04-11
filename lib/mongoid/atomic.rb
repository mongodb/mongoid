# encoding: utf-8
require "mongoid/atomic/modifiers"
require "mongoid/atomic/paths"

module Mongoid #:nodoc:

  # This module contains the logic for supporting atomic operations against the
  # database.
  module Atomic
    extend ActiveSupport::Concern

    UPDATES = [
      :atomic_array_pushes,
      :atomic_array_pulls,
      :atomic_array_add_to_sets,
      :atomic_pulls,
      :atomic_unsets,
      :delayed_atomic_sets,
      :delayed_atomic_pulls
    ]

    included do

      # When MongoDB finally fully implements the positional operator, we can
      # get rid of all indexing related code in Mongoid.
      attr_accessor :_index
    end

    # Add the document as an atomic pull.
    #
    # @example Add the atomic pull.
    #   person.add_atomic_pull(address)
    #
    # @param [ Document ] The embedded document to pull.
    #
    # @since 2.2.0
    def add_atomic_pull(document)
      document.flagged_for_destroy = true
      (delayed_atomic_pulls[document.metadata.name.to_s] ||= []).push(document)
    end

    # For array fields these are the pushes that need to happen.
    #
    # @example Get the array pushes.
    #   person.atomic_array_pushes
    #
    # @return [ Hash ] The array pushes.
    #
    # @since 2.4.0
    def atomic_array_pushes
      @atomic_array_pushes ||= {}
    end

    # For array fields these are the pulls that need to happen.
    #
    # @example Get the array pulls.
    #   person.atomic_array_pulls
    #
    # @return [ Hash ] The array pulls.
    #
    # @since 2.4.0
    def atomic_array_pulls
      @atomic_array_pulls ||= {}
    end

    # For array fields these are the unique adds that need to happen.
    #
    # @example Get the array unique adds.
    #   person.atomic_array_add_to_sets
    #
    # @return [ Hash ] The array add_to_sets.
    #
    # @since 2.4.0
    def atomic_array_add_to_sets
      @atomic_array_add_to_sets ||= {}
    end

    # Get all the atomic updates that need to happen for the current
    # +Document+. This includes all changes that need to happen in the
    # entire hierarchy that exists below where the save call was made.
    #
    # @note MongoDB does not allow "conflicting modifications" to be
    #   performed in a single operation. Conflicting modifications are
    #   detected by the 'haveConflictingMod' function in MongoDB.
    #   Examination of the code suggests that two modifications (a $set
    #   and a $pushAll, for example) conflict if:
    #     (1) the key paths being modified are equal.
    #     (2) one key path is a prefix of the other.
    #   So a $set of 'addresses.0.street' will conflict with a $pushAll
    #   to 'addresses', and we will need to split our update into two
    #   pieces. We do not, however, attempt to match MongoDB's logic
    #   exactly. Instead, we assume that two updates conflict if the
    #   first component of the two key paths matches.
    #
    # @example Get the updates that need to occur.
    #   person.atomic_updates(children)
    #
    # @return [ Hash ] The updates and their modifiers.
    #
    # @since 2.1.0
    def atomic_updates
      mods = Modifiers.new
      generate_atomic_updates(mods, self)
      _children.each do |child|
        generate_atomic_updates(mods, child)
      end
      mods
    end
    alias :_updates :atomic_updates

    # Get the removal modifier for the document. Will be nil on root
    # documents, $unset on embeds_one, $set on embeds_many.
    #
    # @example Get the removal operator.
    #   name.atomic_delete_modifier
    #
    # @return [ String ] The pull or unset operation.
    def atomic_delete_modifier
      atomic_paths.delete_modifier
    end

    # Get the insertion modifier for the document. Will be nil on root
    # documents, $set on embeds_one, $push on embeds_many.
    #
    # @example Get the insert operation.
    #   name.atomic_insert_modifier
    #
    # @return [ String ] The pull or set operator.
    def atomic_insert_modifier
      atomic_paths.insert_modifier
    end

    # Return the path to this +Document+ in JSON notation, used for atomic
    # updates via $set in MongoDB.
    #
    # @example Get the path to this document.
    #   address.atomic_path
    #
    # @return [ String ] The path to the document in the database.
    def atomic_path
      atomic_paths.path
    end

    # Returns the positional operator of this document for modification.
    #
    # @example Get the positional operator.
    #   address.atomic_position
    #
    # @return [ String ] The positional operator with indexes.
    def atomic_position
      atomic_paths.position
    end

    # Returns path of the attribute for modification
    #
    # @example Get path of the attribute
    #   address.atomic_attribute_name(:city)
    #
    # @return [ String ] The path to the document attribute in the database
    def atomic_attribute_name(name)
      embedded? ? "#{atomic_position}.#{name}" : name
    end

    # Get all the attributes that need to be pulled.
    #
    # @example Get the pulls.
    #   person.atomic_pulls
    #
    # @return [ Array<Hash> ] The $pullAll operations.
    #
    # @since 2.2.0
    def atomic_pulls
      delayed_atomic_pulls.reduce({}) do |pulls, (_, docs)|
        docs.each do |doc|
          (pulls[doc.atomic_path] ||= []).push(doc.as_document)
          doc.destroyed = true
          doc.flagged_for_destroy = false
        end
        pulls
      end
    end

    # Get all the push attributes that need to occur.
    #
    # @example Get the pushes.
    #   person.atomic_pushes
    #
    # @return [ Hash ] The $pushAll operations.
    #
    # @since 2.1.0
    def atomic_pushes
      pushable? ? { atomic_path => as_document } : {}
    end

    # Return the selector for this document to be matched exactly for use
    # with MongoDB's $ operator.
    #
    # @example Get the selector.
    #   address.atomic_selector
    #
    # @return [ String ] The exact selector for this document.
    def atomic_selector
      atomic_paths.selector
    end

    # Get all the attributes that need to be set.
    #
    # @example Get the sets.
    #   person.atomic_sets
    #
    # @return [ Hash ] The $set operations.
    #
    # @since 2.1.0
    def atomic_sets
      updateable? ? setters : settable? ? { atomic_path => as_document } : {}
    end

    # Get all the attributes that need to be unset.
    #
    # @example Get the unsets.
    #   person.atomic_unsets
    #
    # @return [ Array<Hash> ] The $unset operations.
    #
    # @since 2.2.0
    def atomic_unsets
      @atomic_unsets ||= []
    end

    # Get all the atomic sets that have had their saves delayed.
    #
    # @example Get the delayed atomic sets.
    #   person.delayed_atomic_sets
    #
    # @return [ Hash ] The delayed $sets.
    #
    # @since 2.3.0
    def delayed_atomic_sets
      @delayed_atomic_sets ||= {}
    end

    # Get a hash of atomic pulls that are pending.
    #
    # @example Get the atomic pulls.
    #   document.delayed_atomic_pulls
    #
    # @return [ Hash ] name/document pairs.
    #
    # @since 2.3.2
    def delayed_atomic_pulls
      @delayed_atomic_pulls ||= {}
    end

    private

    # Get the atomic paths utility for this document.
    #
    # @example Get the atomic paths.
    #   document.atomic_paths
    #
    # @return [ Object ] The associated path.
    #
    # @since 2.1.0
    def atomic_paths
      @atomic_paths ||= metadata ? metadata.path(self) : Atomic::Paths::Root.new(self)
    end

    # Generates the atomic updates in the correct order.
    #
    # @example Generate the updates.
    #   model.generate_atomic_updates(mods, doc)
    #
    # @param [ Modifiers ] mods The atomic modifications.
    # @param [ Document ] doc The document to update for.
    #
    # @since 2.2.0
    def generate_atomic_updates(mods, doc)
      mods.unset(doc.atomic_unsets)
      mods.pull(doc.atomic_pulls)
      mods.set(doc.atomic_sets)
      mods.set(doc.delayed_atomic_sets)
      mods.push(doc.atomic_pushes)
      mods.push(doc.atomic_array_pushes)
      mods.add_to_set(doc.atomic_array_add_to_sets)
      mods.pull(doc.atomic_array_pulls)
    end
  end
end
