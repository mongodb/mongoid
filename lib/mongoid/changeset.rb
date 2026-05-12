# frozen_string_literal: true

require 'mongoid/changeset/entry'

module Mongoid
  class Changeset
    attr_reader :entries, :depth

    def initialize
      @entries    = []
      @depth      = 0
      @terminated = false
    end

    # Manages nesting depth. Inner calls accumulate without flushing.
    def build
      @depth += 1
      yield
    ensure
      @depth -= 1
    end

    # Outer entry point — increments depth, yields, decrements depth.
    # When depth returns to zero (outermost scope), flushes. On error at
    # the outermost scope, discards.
    def run(&block)
      raise Errors::InvalidOperation.new('Changeset is terminated') if terminated?

      build(&block)
      flush if @depth.zero?
    rescue StandardError
      discard if @depth.zero?
      raise
    end

    # Appends an entry to the list.
    def add(entry)
      raise Errors::InvalidOperation.new('Changeset is terminated') if terminated?

      @entries << entry
    end

    # Executes all entries against the driver in registration order, then
    # marks the changeset terminated. Full implementation in Task 6.
    def flush
      raise Errors::InvalidOperation.new('Changeset is terminated') if terminated?

      _flush_entries
      @terminated = true
    end

    # Clears all staged entries without executing them, then marks terminated.
    def discard
      raise Errors::InvalidOperation.new('Changeset is terminated') if terminated?

      @entries.clear
      @terminated = true
    end

    # Returns true if the changeset has been flushed or discarded.
    def terminated?
      @terminated
    end

    private

    def _flush_entries
      _build_batches(@entries).each do |batch|
        batch.each do |entry|
          entry.document&.run_callbacks(:before_flush)
        end

        if batch.size == 1
          _execute_single(batch.first)
        else
          _execute_bulk(batch)
        end

        batch.each do |entry|
          _update_document_state(entry)
          entry.document&.run_callbacks(:after_flush)
        end
      end

      @entries.each { |entry| _dispatch_commit(entry) }
    end

    def _dispatch_commit(entry)
      doc = entry.document
      return unless doc

      if entry.session&.in_transaction?
        Mongoid::Threaded.add_modified_document(entry.session, doc)
      else
        doc.run_callbacks(:commit)
      end
    end

    def _build_batches(entries)
      batches = []
      entries.each do |entry|
        if batches.last&.first&.collection == entry.collection
          batches.last << entry
        else
          batches << [ entry ]
        end
      end
      batches
    end

    def _execute_single(entry)
      opts = entry.session ? { session: entry.session } : {}
      case entry.type
      when :insert
        entry.collection.insert_one(entry.payload, **opts)
      when :update
        entry.collection.find(entry.selector).update_one(entry.payload, **opts)
      when :update_many
        entry.collection.find(entry.selector).update_many(entry.payload, **opts)
      when :delete
        entry.collection.find(entry.selector).delete_one(**opts)
      when :delete_many
        entry.collection.find(entry.selector).delete_many(**opts)
      end
    end

    def _execute_bulk(batch)
      collection = batch.first.collection
      session = batch.map(&:session).find { |s| s }
      opts = session ? { session: session } : {}
      ops = batch.map { |entry| _bulk_op_for(entry) }
      collection.bulk_write(ops, **opts)
    end

    def _bulk_op_for(entry)
      case entry.type
      when :insert
        { insert_one: entry.payload }
      when :update
        { update_one: { filter: entry.selector, update: entry.payload } }
      when :update_many
        { update_many: { filter: entry.selector, update: entry.payload } }
      when :delete
        { delete_one: { filter: entry.selector } }
      when :delete_many
        { delete_many: { filter: entry.selector } }
      end
    end

    def _update_document_state(entry)
      doc = entry.document
      return unless doc

      case entry.type
      when :insert
        doc.new_record = false
        doc.remember_storage_options!
        doc.flag_descendants_persisted
      when :delete
        doc.destroyed = true
      end
    end
  end
end
