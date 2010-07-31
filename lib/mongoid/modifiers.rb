# encoding: utf-8
require "mongoid/modifiers/command"
require "mongoid/modifiers/inc"

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
      current = send(field)
      write_attribute(field, (current ? (current + value) : value))
      Inc.new(self, options).persist(field, value)
      current + value
    end
  end
end
