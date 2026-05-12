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
      # Task 6: batch grouping and driver execution
    end
  end
end
