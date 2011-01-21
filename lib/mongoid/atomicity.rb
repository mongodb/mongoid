# encoding: utf-8
module Mongoid #:nodoc:

  # This module contains the logic for supporting atomic operations against the
  # database.
  #
  # @todo Durran: Refactor class out into separate objects for each type of
  #   update.
  module Atomicity
    extend ActiveSupport::Concern

    # Get all the atomic updates that need to happen for the current
    # +Document+. This includes all changes that need to happen in the
    # entire hierarchy that exists below where the save call was made.
    #
    # @note
    #   MongoDB does not allow "conflicting modifications" to be
    #   performed in a single operation.  Conflicting modifications are
    #   detected by the 'haveConflictingMod' function in MongoDB.
    #   Examination of the code suggests that two modifications (a $set
    #   and a $pushAll, for example) conflict if:
    #     (1) the key paths being modified are equal.
    #     (2) one key path is a prefix of the other.
    #   So a $set of 'addresses.0.street' will conflict with a $pushAll
    #   to 'addresses', and we will need to split our update into two
    #   pieces.  We do not, however, attempt to match MongoDB's logic
    #   exactly.  Instead, we assume that two updates conflict if the
    #   first component of the two key paths matches.
    #
    # @example Get the updates that need to occur.
    #   person._updates
    #
    # @return [ Hash ] The updates and their modifiers.
    def _updates
      processed = {}

      _children.inject({ "$set" => _sets, "$pushAll" => {}, :other => {} }) do |updates, child|
        changes = child._sets
        updates["$set"].update(changes)
        unless changes.empty?
          processed[child._conficting_modification_key] = true
        end

        if processed.has_key?(child._conficting_modification_key)
          target = :other
        else
          target = "$pushAll"
        end

        child._pushes.each do |attr, val|
          if updates[target].has_key?(attr)
            updates[target][attr] << val
          else
            updates[target].update({attr => [val]})
          end
        end
        updates
      end.delete_if do |key, value|
        value.empty?
      end
    end

    protected

    # Get the key used to check for conflicting modifications.  For now, we
    # just use the first component of _path, and discard the first period
    # and everything that follows.
    #
    # @example Get the key.
    #   person._conflicting_modification_key
    #
    # @return [ String ] The conflicting key.
    def _conficting_modification_key
      _path.sub(/\..*/, '')
    end

    # Get all the push attributes that need to occur.
    #
    # @example Get the pushes.
    #   person._pushes
    #
    # @return [ Hash ] The $pushAll operations.
    def _pushes
      pushable? ? { _path => as_document } : {}
    end

    # Determine if the document can be pushed.
    #
    # @example Is this pushable?
    #   person.pushable?
    #
    # @return [ true, false ] Is the document new and embedded?
    def pushable?
      new_record? && embedded_many? && _parent.persisted?
    end

    # Get all the attributes that need to be set.
    #
    # @example Get the sets.
    #   person._sets
    #
    # @return [ Hash ] The $set operations.
    def _sets
      if changed? && !new_record?
        setters
      else
        embedded_one? && new_record? ? { _path => as_document } : {}
      end
    end
  end
end
