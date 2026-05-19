# frozen_string_literal: true

require 'mongoid/changeset/entry'

module Mongoid
  class Changeset
    attr_reader :entries, :depth

    def atomically_context?
      @atomically_context
    end

    def enter_atomically_context
      @atomically_context = true
    end

    def exit_atomically_context
      @atomically_context = false
    end

    def initialize
      @entries           = []
      @depth             = 0
      @terminated        = false
      @atomically_context = false
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
      raise Errors::InvalidChangesetOperation.new('Changeset is terminated') if terminated?

      result = build(&block)
      flush if @depth.zero?
      result
    rescue StandardError
      discard if @depth.zero? && !terminated?
      raise
    end

    # Constructs an Entry from the given keyword arguments and appends it.
    def add(**kwargs)
      add_entry(Entry.new(**kwargs))
    end

    # Appends a pre-built Entry to the list.
    def add_entry(entry)
      raise Errors::InvalidChangesetOperation.new('Changeset is terminated') if terminated?

      @entries << entry
      entry
    end

    # Executes all entries against the driver in registration order, then
    # marks the changeset terminated. Terminates even if the flush is aborted
    # by an exception — a partially-flushed changeset is not resumable.
    def flush
      raise Errors::InvalidChangesetOperation.new('Changeset is terminated') if terminated?

      _flush_entries
    ensure
      @terminated = true
    end

    # Clears all staged entries without executing them, then marks terminated.
    def discard
      raise Errors::InvalidChangesetOperation.new('Changeset is terminated') if terminated?

      @entries.clear
      @terminated = true
    end

    # Returns true if the changeset has been flushed or discarded.
    def terminated?
      @terminated
    end

    private

    def _flush_entries
      @entries.reject(&:skip_callbacks)
              .filter_map(&:document)
              .uniq { |d| d.object_id }
              .each { |doc| doc.run_before_callbacks(:flush) }

      _build_batches(@entries).each do |batch|
        (batch.size == 1) ? _execute_single(batch.first) : _execute_bulk(batch)
        _finalize_batch(batch)
      end

      _dispatch_commits
    end

    def _finalize_batch(batch)
      per_doc = {}.compare_by_identity
      batch.each do |entry|
        next unless entry.document

        per_doc[entry.document] ||= { entries: [], callbacks: false, dirty_fields: [] }
        per_doc[entry.document][:entries] << entry
        per_doc[entry.document][:callbacks] ||= !entry.skip_callbacks
        per_doc[entry.document][:dirty_fields].concat(entry.dirty_fields) if entry.dirty_fields
      end

      per_doc.each do |doc, data|
        data[:entries].each { |e| _update_document_state(e) }
        data[:dirty_fields].each { |f| doc.remove_change(f) }
        doc.run_after_callbacks(:flush) if data[:callbacks]
      end
    end

    def _dispatch_commits
      seen = {}.compare_by_identity
      @entries.each do |entry|
        next unless entry.document

        rec = (seen[entry.document] ||= { session: nil, callbacks: false })
        rec[:session] ||= entry.session
        rec[:callbacks] ||= !entry.skip_callbacks
      end

      seen.each do |doc, data|
        if data[:session]&.in_transaction?
          Mongoid::Threaded.add_modified_document(data[:session], doc)
        elsif data[:callbacks]
          doc.run_callbacks(:commit)
        end
      end
    end

    def _build_batches(entries)
      batches = []
      entries.each do |entry|
        last = batches.last&.first
        if last&.collection == entry.collection && last&.session.equal?(entry.session)
          batches.last << entry
        else
          batches << [ entry ]
        end
      end
      batches
    end

    def _execute_single(entry)
      session_opts = entry.session ? { session: entry.session } : {}
      driver_opts = entry.opts ? session_opts.merge(entry.opts) : session_opts
      opt_args = _opt_args(driver_opts)
      case entry.type
      when :insert
        entry.collection.insert_one(entry.payload, *opt_args)
      when :update, :embedded_insert, :embedded_delete
        entry.collection.find(entry.selector).update_one(entry.payload, *opt_args)
      when :update_many
        entry.collection.find(entry.selector).update_many(entry.payload, *opt_args)
      when :delete
        entry.collection.find(entry.selector).delete_one(*opt_args)
      when :delete_many
        entry.result = entry.collection.find(entry.selector).delete_many(*opt_args)
      when :upsert
        entry.collection.find(entry.selector).update_one(entry.payload, { upsert: true }.merge(driver_opts))
      when :upsert_replace
        entry.collection.find(entry.selector).replace_one(entry.payload, { upsert: true }.merge(driver_opts))
      end
    end

    def _execute_bulk(batch)
      collection = batch.first.collection
      session = batch.map(&:session).find { |s| s }
      opts = session ? { session: session } : {}
      ops = batch.map { |entry| _bulk_op_for(entry) }
      collection.bulk_write(ops, *_opt_args(opts))
    end

    # The mongo 2.x driver takes positional opts hashes. Passing **{} in Ruby 2.7
    # is converted to a positional {} argument, causing RSpec argument mismatches
    # in tests. Omit the opts argument entirely when there is nothing to pass.
    def _opt_args(opts)
      opts.empty? ? [] : [ opts ]
    end

    def _bulk_op_for(entry)
      inner_opts = entry.opts&.reject { |k, _| k == :session } || {}
      case entry.type
      when :insert
        { insert_one: entry.payload }
      when :update, :embedded_insert, :embedded_delete
        { update_one: { filter: entry.selector, update: entry.payload }.merge(inner_opts) }
      when :update_many
        { update_many: { filter: entry.selector, update: entry.payload }.merge(inner_opts) }
      when :delete
        { delete_one: { filter: entry.selector }.merge(inner_opts) }
      when :delete_many
        { delete_many: { filter: entry.selector }.merge(inner_opts) }
      else
        _bulk_op_for_upsert(entry, inner_opts)
      end
    end

    def _bulk_op_for_upsert(entry, inner_opts)
      case entry.type
      when :upsert
        { update_one: { filter: entry.selector, update: entry.payload, upsert: true }.merge(inner_opts) }
      when :upsert_replace
        { replace_one: { filter: entry.selector, replacement: entry.payload, upsert: true }.merge(inner_opts) }
      end
    end

    def _update_document_state(entry)
      doc = entry.document
      return unless doc

      case entry.type
      when :insert, :embedded_insert, :upsert, :upsert_replace
        doc.new_record = false
        doc.remember_storage_options!
        doc.flag_descendants_persisted
        doc._reset_memoized_descendants!
      when :update, :update_many
        # no per-document state change needed for updates
      when :embedded_delete, :delete
        doc.destroyed = true
      end
    end
  end
end
