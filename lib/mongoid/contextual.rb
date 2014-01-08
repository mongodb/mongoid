# encoding: utf-8
require "mongoid/contextual/queryable"
require "mongoid/contextual/mongo"
require "mongoid/contextual/memory"
require "mongoid/contextual/none"

module Mongoid
  module Contextual

    # The aggregate operations provided in the aggregate module get delegated
    # through to the context from the criteria.
    delegate(*Aggregable::Mongo.public_instance_methods(false), to: :context)

    # The atomic operations provided in the atomic context get delegated
    # through to the context from the criteria.
    delegate(*Atomic.public_instance_methods(false), to: :context)

    # The methods in the contexts themselves should all get delegated to,
    # including destructive, modification, and optional methods.
    delegate(*(Mongo.public_instance_methods(false) - [ :skip, :limit ]), to: :context)

    # This gets blank and empty included.
    delegate(*Queryable.public_instance_methods(false), to: :context)

    # Get the context in which criteria queries should execute. This is either
    # in memory (for embedded documents) or mongo (for root level documents.)
    #
    # @example Get the context.
    #   criteria.context
    #
    # @return [ Memory, Mongo ] The context.
    #
    # @since 3.0.0
    def context
      @context ||= create_context
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
    # @return [ Mongo, Memory ] The context.
    #
    # @since 3.0.0
    def create_context
      return None.new(self) if empty_and_chainable?
      embedded ? Memory.new(self) : Mongo.new(self)
    end
  end
end
