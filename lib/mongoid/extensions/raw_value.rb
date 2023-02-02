# frozen_string_literal: true

# Wrapper class used when a value cannot be casted in evolve method.
module Mongoid
  def RawValue(*args)
    RawValue.new(*args)
  end

  class RawValue

    attr_reader :raw_value

    def initialize(raw_value)
      @raw_value = raw_value
    end

    # Returns a string containing a human-readable representation of
    # the object, including the inspection of the underlying value.
    #
    # @return [ String ] The object inspection.
    def inspect
      "RawValue: #{raw_value.inspect}"
    end
  end
end