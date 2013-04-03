# encoding: utf-8
require "mongoid/persistable/atomic/operation"
require "mongoid/persistable/atomic/add_to_set"

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
    end
  end
end
