# frozen_string_literal: true

module Mongoid

  # Mixin which overrides ActiveSupport's default deprecation
  # behavior added to Module class.
  module Deprecatable

    # Declares method(s) as deprecated.
    #
    # @example Deprecate a method.
    #   Cat.deprecate(:meow); Cat.new.meow
    #   #=> Mongoid.logger.warn("meow is deprecated and will be removed from Mongoid 8.0")
    #
    # @example Deprecate a method and declare the replacement method.
    #   Cat.deprecate(meow: :speak); Cat.new.meow
    #   #=> Mongoid.logger.warn("meow is deprecated and will be removed from Mongoid 8.0 (use speak instead)")
    #
    # @example Deprecate a method and give replacement instructions.
    #   Cat.deprecate(meow: 'eat :catnip instead'); Cat.new.meow
    #   #=> Mongoid.logger.warn("meow is deprecated and will be removed from Mongoid 8.0 (eat :catnip instead)")
    #
    # @param [ Symbol | Hash<Symbol, [Symbol|String]> ]
    def deprecate(*method_descriptors)
      Mongoid::Deprecation.deprecate_methods(self, *method_descriptors)
    end
  end
end
