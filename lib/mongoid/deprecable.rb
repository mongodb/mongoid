# frozen_string_literal: true

require "mongoid/deprecation"

module Mongoid

  # Adds ability to declare Mongoid-specific deprecations.
  #
  # @api private
  module Deprecable

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
      Mongoid::Deprecation.deprecate_methods(target_module, *method_descriptors)
    end
  end
end

# Ensure Mongoid.deprecate can be used during initialization
Mongoid.extend(Mongoid::Deprecable)
