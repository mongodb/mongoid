# frozen_string_literal: true

module Mongoid

  # Utility functions for Mongoid.
  #
  # @api private
  module Utils

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
    module_function def monotonic_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
