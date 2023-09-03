# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module Extensions

    # Adds type-casting behavior to TrueClass
    module TrueClass

      # Is the passed value a boolean?
      #
      # @example Is the value a boolean type?
      #   true.is_a?(Boolean)
      #
      # @param [ Class ] other The class to check.
      #
      # @return [ true | false ] If the other is a boolean.
      def is_a?(other)
        if other == Mongoid::Boolean || other.class == Mongoid::Boolean
          return true
        end
        super(other)
      end
    end
  end
end

::TrueClass.__send__(:include, Mongoid::Extensions::TrueClass)
