# frozen_string_literal: true

require 'mongoid/deprecation'

module Mongoid
  # Adds ability to declare Mongoid-specific deprecations.
  #
  # @api private
  module Deprecable
    # A Mongoid::Deprecation instance to use for reporting deprecations
    def deprecator
      @deprecator ||= Mongoid::Deprecation.new
    end

    # Resets all deprecation warnings. For use in tests.
    def reset_deprecation_warnings!
      DEPRECATION_WARNING_MUTEX.synchronize { @deprecation_warnings = {} }
    end

    # Emits a warning using the current deprecator. If the given warning (as
    # identified by `id`) has already been issued previously, this is a no-op.
    #
    # @param [ Symbol ] id The unique identifier for this warning.
    # @param [ String ] warning The warning message to emit.
    # @param [ Array<Thread::Backtrace::Location> | nil ] callstack The backtrace at the call site.
    def deprecation_warning(id, warning, callstack = nil)
      site = callstack&.first
      deprecation_warning_guard(id, site ? "#{site.path}:#{site.lineno}" : nil) do
        deprecator.warn(warning, callstack)
      end
    end

    # Declares method(s) as deprecated.
    #
    # @example Deprecate a method.
    #   Mongoid.deprecate(Cat, :meow); Cat.new.meow
    #   #=> Mongoid.logger.warn("meow is deprecated and will be removed from Mongoid 8.0")
    #
    # @example Deprecate a method and declare the replacement method.
    #   Mongoid.deprecate(Cat, meow: :speak); Cat.new.meow
    #   #=> Mongoid.logger.warn("meow is deprecated and will be removed from Mongoid 8.0 (use speak instead)")
    #
    # @example Deprecate a method and give replacement instructions.
    #   Mongoid.deprecate(Cat, meow: 'eat :catnip instead'); Cat.new.meow
    #   #=> Mongoid.logger.warn("meow is deprecated and will be removed from Mongoid 8.0 (eat :catnip instead)")
    #
    # @param [ Module ] target_module The parent which contains the method.
    # @param [ [ Symbol | Hash<Symbol, [ Symbol | String ]> ]... ] *method_descriptors
    #   The methods to deprecate, with optional replacement instructions.
    def deprecate(target_module, *method_descriptors)
      deprecator.deprecate_methods(target_module, *method_descriptors)
    end

    private

    # The Mutex instance used to guard the deprecation warning flags.
    DEPRECATION_WARNING_MUTEX = Mutex.new

    # Wraps access to the warnings Hash in a synchronize block. If the given
    # id+callsite has not been warned already, the method will yield to a block and then
    # flag the id. Otherwise, it returns immediately.
    def deprecation_warning_guard(id, callsite)
      DEPRECATION_WARNING_MUTEX.synchronize do
        @deprecation_warnings ||= {}

        key = "#{id}:#{callsite}"
        return if @deprecation_warnings.key?(key)

        yield

        @deprecation_warnings[key] = true
      end
    end
  end
end

# Ensure Mongoid.deprecate can be used during initialization
Mongoid.extend(Mongoid::Deprecable)
