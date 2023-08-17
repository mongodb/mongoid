# frozen_string_literal: true

module Mongoid
  # Utility functions for Mongoid.
  #
  # @api private
  module Utils
    extend self

    # A unique placeholder value that will never accidentally collide with
    # valid values. This is useful as a default keyword argument value when
    # you want the argument to be optional, but you also want to be able to
    # recognize that the caller did not provide a value for it.
    PLACEHOLDER = Object.new.freeze

    # Asks if the given value is a placeholder or not.
    #
    # @param [ Object ] value the value to compare
    #
    # @return [ true | false ] if the value is a placeholder or not.
    def placeholder?(value)
      value == PLACEHOLDER
    end

    # If value can be coerced to an integer, return it as an integer.
    # Otherwise, return the value itself.
    #
    # @param [ String ] value the string to possibly coerce.
    #
    # @return [ String | Integer ] the result of the coercion.
    def maybe_integer(value)
      if value.match?(/^\d/)
        value.to_i
      else
        value
      end
    end

    # This function should be used if you need to measure time.
    # @example Calculate elapsed time.
    #   starting = Utils.monotonic_time
    #   # do something time consuming
    #   ending = Utils.monotonic_time
    #   puts "It took #{(ending - starting).to_i} seconds"
    #
    # @see https://blog.dnsimple.com/2018/03/elapsed-time-with-ruby-the-right-way/
    #
    # @return [Float] seconds according to monotonic clock
    #
    # @api private
    def monotonic_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
