# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module Extensions

    # Adds type-casting behavior to FalseClass.
    module FalseClass

      # Is the passed value a boolean?
      #
      # @example Is the value a boolean type?
      #   false.is_a?(Boolean)
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

::FalseClass.__send__(:include, Mongoid::Extensions::FalseClass)
