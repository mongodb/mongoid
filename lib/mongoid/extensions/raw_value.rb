# frozen_string_literal: true
# rubocop:todo all

# Wrapper class used when a value cannot be casted in evolve method.
module Mongoid

  # Instantiates a new Mongoid::RawValue object. Used as a syntax shortcut.
  #
  # @example Create a Mongoid::RawValue object.
  #   Mongoid::RawValue("Beagle")
  #
  # @return [ Mongoid::RawValue ] The object.
  def RawValue(*args)
    RawValue.new(*args)
  end

  # Represents a value which cannot be type-casted between Ruby and MongoDB.
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
