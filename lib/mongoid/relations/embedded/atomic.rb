# encoding: utf-8
require "mongoid/relations/embedded/atomic/set"

module Mongoid #:nodoc:
  module Relations #:nodoc:
    module Embedded #:nodoc:

      # This module provides the ability for calls to be declared atomic.
      module Atomic

        private

        MODIFIERS = {
          :$set => Set
        }

        # Executes a block of commands in an atomic fashion. Mongoid will
        # intercept all database upserts while in this block and combine them
        # into a single database call. When the block concludes the atomic
        # update will occur.
        #
        # Since the collection is accessed through the class it would not be
        # thread safe to give it state so we access the atomic updater via the
        # current thread.
        #
        # @note This operation is not safe when attemping to do illegal updates
        #   for different objects or collections, since the updator is not
        #   scoped on the thread. This is meant for Mongoid internal use only
        #   to keep existing design clean.
        #
        # @example Atomically $set multiple saves.
        #   atomically(:$set) do
        #     address_one.save!
        #     address_two.save!
        #   end
        #
        # @example Atomically $pushAll multiple new docs.
        #   atomically(:$pushAll) do
        #     person.addresses.push([ address_one, address_two ])
        #   end
        #
        # @param [ Symbol ] modifier The atomic modifier to perform.
        # @param [ Proc ] block The block to execute.
        #
        # @return [ Object ] The result of the operation.
        #
        # @since 2.0.0
        def atomically(modifier, &block)
          @executions ||= 0
          @executions += 1
          updater = Thread.current[:mongoid_atomic_update] ||= MODIFIERS[modifier].new
          block.call if block
          @executions -= 1
          if @executions.zero?
            Thread.current[:mongoid_atomic_update] = nil
            updater.execute(collection)
          end
        end
      end
    end
  end
end
