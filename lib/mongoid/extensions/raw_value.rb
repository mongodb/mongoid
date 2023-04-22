# frozen_string_literal: true
# rubocop:todo all

# Wrapper class used when a value cannot be casted by the
# mongoize, demongoize, and evolve methods.
module Mongoid

  # Instantiates a new Mongoid::RawValue object. Used as a
  # syntax shortcut.
  #
  # @example Create a Mongoid::RawValue object.
  #   Mongoid::RawValue("Beagle")
  #
  # @param [ Object ] raw_value The underlying raw object.
  # @param [ String ] cast_class_name The name of the class
  #   to which the raw value is intended to be cast.
  #
  # @return [ Mongoid::RawValue ] The object.
  def RawValue(raw_value, cast_class_name = nil)
    RawValue.new(raw_value, cast_class_name)
  end

  class RawValue

    attr_reader :raw_value,
                :cast_class_name

    # Instantiates a new Mongoid::RawValue object.
    #
    # @example Create a Mongoid::RawValue object.
    #   Mongoid::RawValue.new("Beagle", "String")
    #
    # @param [ Object ] raw_value The underlying raw object.
    # @param [ String ] cast_class_name The name of the class
    #   to which the raw value is intended to be cast.
    #
    # @return [ Mongoid::RawValue ] The object.
    def initialize(raw_value, cast_class_name = nil)
      @raw_value = raw_value
      @cast_class_name = cast_class_name
    end

    # Returns a string containing a human-readable representation of
    # the object, including the inspection of the underlying value.
    #
    # @return [ String ] The object inspection.
    def inspect
      "RawValue: #{raw_value.inspect}"
    end

    # Raises a Mongoid::Errors::InvalidValue error.
    def raise_error!
      raise Mongoid::Errors::InvalidValue.new(raw_value.class.name, cast_class_name)
    end

    # Logs a warning that a value cannot be cast.
    def warn
      Mongoid.logger.warn("Cannot cast #{raw_value.class.name} to #{cast_class_name}; returning nil")
    end

    # Delegate all missing methods to the raw value.
    #
    # @param [ String, Symbol ] method_name The name of the method.
    # @param [ Array ] args The arguments passed to the method.
    #
    # @return [ Object ] The method response.
    ruby2_keywords def method_missing(method_name, *args, &block)
      raw_value.send(method_name, *args, &block)
    end

    # Delegate all missing methods to the raw value.
    #
    # @param [ String, Symbol ] method_name The name of the method.
    # @param [ true | false ] include_private Whether to check private methods.
    #
    # @return [ true | false ] Whether the raw value object responds to the method.
    def respond_to_missing?(method_name, include_private = false)
      raw_value.respond_to?(method_name, include_private)
    end
  end
end
