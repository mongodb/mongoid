# frozen_string_literal: true

require "mongoid/contextual/queryable"
require "mongoid/contextual/mongo"
require "mongoid/contextual/memory"
require "mongoid/contextual/none"

module Mongoid
  module Contextual
    extend Forwardable

    # The aggregate operations provided in the aggregate module get delegated
    # through to the context from the criteria.
    def_delegators :context, *Aggregable::Mongo.public_instance_methods(false)

    # The atomic operations provided in the atomic context get delegated
    # through to the context from the criteria.
    def_delegators :context, *Atomic.public_instance_methods(false)

    # The methods in the contexts themselves should all get delegated to,
    # including destructive, modification, and optional methods.
    def_delegators :context, *(Mongo.public_instance_methods(false) - [ :skip, :limit ])

    # This gets blank and empty included.
    def_delegators :context, *Queryable.public_instance_methods(false)

    # Get the context in which criteria queries should execute. This is either
    # in memory (for embedded documents) or mongo (for root level documents.)
    #
    # @example Get the context.
    #   criteria.context
    #
    # @return [ Memory | Mongo ] The context.
    def context
      @context ||= create_context
    end

    # Instructs the context to schedule an asynchronous loading of documents
    # specified by the criteria.
    #
    # Note that depending on the context and on the Mongoid configuration,
    # documents can be loaded synchronously on the caller's thread.
    #
    # @return [ Criteria ] Returns self.
    def load_async
      context.load_async if context.respond_to?(:load_async)
      self
    end

    private

    # Create the context for the queries to execute. Will be memory for
    # embedded documents and mongo for root documents.
    #
    # @api private
    #
    # @example Create the context.
    #   contextual.create_context
    #
    # @return [ Mongo | Memory ] The context.
    def create_context
      return None.new(self) if empty_and_chainable?
      embedded ? Memory.new(self) : Mongo.new(self)
    end
  end
end
