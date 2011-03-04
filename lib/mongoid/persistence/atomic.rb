# encoding: utf-8
require "mongoid/persistence/atomic/operation"
require "mongoid/persistence/atomic/add_to_set"
require "mongoid/persistence/atomic/inc"
require "mongoid/persistence/atomic/pull_all"
require "mongoid/persistence/atomic/push"

module Mongoid #:nodoc:
  module Persistence #:nodoc:

    # This module provides the explicit atomic operations helpers on the
    # document itself.
    module Atomic

      # Performs an atomic $addToSet of the provided value on the supplied field.
      # If the field does not exist it will be initialized as an empty array.
      #
      # If the value already exists on the array it will not be added.
      #
      # @example Add only a unique value on the field.
      #   person.add_to_set(:aliases, "Bond")
      #
      # @param [ Symbol ] field The name of the field.
      # @param [ Object ] value The value to add.
      # @param [ Hash ] options The mongo persistence options.
      #
      # @return [ Array<Object> ] The new value of the field.
      #
      # @since 2.0.0
      def add_to_set(field, value, options = {})
        AddToSet.new(self, field, value, options).persist
      end

      # Performs an atomic $inc of the provided value on the supplied
      # field. If the field does not exist it will be initialized as
      # the provided value.
      #
      # @example Increment a field.
      #   person.inc(:score, 2)
      #
      # @param [ Symbol ] field The name of the field.
      # @param [ Integer ] value The value to increment.
      # @param [ Hash ] options The mongo persistence options.
      #
      # @return [ Array<Object> ] The new value of the field.
      #
      # @since 2.0.0
      def inc(field, value, options = {})
        Inc.new(self, field, value, options).persist
      end

      # Performs an atomic $pullAll of the provided value on the supplied
      # field. If the field does not exist it will be initialized as an
      # empty array.
      #
      # @example Pull the values from the field.
      #   person.pull_all(:aliases, [ "Bond", "James" ])
      #
      # @param [ Symbol ] field The name of the field.
      # @param [ Array<Object> ] value The values to pull.
      # @param [ Hash ] options The mongo persistence options.
      #
      # @return [ Array<Object> ] The new value of the field.
      #
      # @since 2.0.0
      def pull_all(field, value, options = {})
        PullAll.new(self, field, value, options).persist
      end

      # Performs an atomic $push of the provided value on the supplied field. If
      # the field does not exist it will be initialized as an empty array.
      #
      # @example Push a value on the field.
      #   person.push(:aliases, "Bond")
      #
      # @param [ Symbol ] field The name of the field.
      # @param [ Object ] value The value to push.
      # @param [ Hash ] options The mongo persistence options.
      #
      # @return [ Array<Object> ] The new value of the field.
      #
      # @since 2.0.0
      def push(field, value, options = {})
        Push.new(self, field, value, options).persist
      end
    end
  end
end
