# encoding: utf-8
require "mongoid/persistable/atomic/operation"
require "mongoid/persistable/atomic/add_to_set"
require "mongoid/persistable/atomic/pull"
require "mongoid/persistable/atomic/pull_all"
require "mongoid/persistable/atomic/push"
require "mongoid/persistable/atomic/push_all"

module Mongoid
  module Persistable

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
      # @example Add only the unique values to the field.
      #   person.add_to_set(:aliases, [ "Bond", "James" ])
      #
      # @param [ Symbol ] field The name of the field.
      # @param [ Object, Array<Object> ] value The value or values to add.
      # @param [ Hash ] options The mongo persistence options.
      #
      # @return [ Array<Object> ] The new value of the field.
      #
      # @since 2.0.0
      def add_to_set(field, value, options = {})
        AddToSet.new(self, field, value, options).persist
      end

      # Performs an atomic $pull of the provided value on the supplied
      # field.
      #
      # @note Support for a $pull with an expression is not yet supported.
      #
      # @example Pull the value from the field.
      #   person.pull(:aliases, "Bond")
      #
      # @param [ Symbol ] field The name of the field.
      # @param [ Object ] value The value to pull.
      # @param [ Hash ] options The mongo persistence options.
      #
      # @return [ Array<Object> ] The new value of the field.
      #
      # @since 2.1.0
      def pull(field, value, options = {})
        Pull.new(self, field, value, options).persist
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

      # Performs an atomic $pushAll of the provided value on the supplied field. If
      # the field does not exist it will be initialized as an empty array.
      #
      # @example Push the values onto the field.
      #   person.push_all(:aliases, [ "Bond", "James" ])
      #
      # @param [ Symbol ] field The name of the field.
      # @param [ Array<Object> ] value The values to push.
      # @param [ Hash ] options The mongo persistence options.
      #
      # @return [ Array<Object> ] The new value of the field.
      #
      # @since 2.1.0
      def push_all(field, value, options = {})
        PushAll.new(self, field, value, options).persist
      end
    end
  end
end
