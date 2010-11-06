# encoding: utf-8
require "mongoid/modifiers/command"
require "mongoid/modifiers/inc"
require "mongoid/modifiers/add_to_set"

module Mongoid #:nodoc:
  module Modifiers #:nodoc:
    extend ActiveSupport::Concern

    # Increment the field by the provided value, else if it doesn't exists set
    # it to that value.
    #
    # Options:
    #
    # field: The field to increment.
    # value: The value to increment by.
    # options: Options to pass through to the driver.
    def inc(field, value, options = {})
      current = self[field]
      sum = current ? (current + value) : value 
      write_attribute(field, sum)
      Inc.new(self, options).persist(field, value)
      sum
    end

    # Adds value to an array only if it is not in the array already, 
    # else if it doesn't exists set it to that value.
    #
    # Options:
    #
    # field: The array field.
    # value: The value to add to the array.
    # options: Options to pass through to the driver.
    def add_to_set(field, value, options = {})
      current = send(field) || []
      write_attribute(field, (current << value))
      AddToSet.new(self, options).persist(field, value)
    end
  end
end
