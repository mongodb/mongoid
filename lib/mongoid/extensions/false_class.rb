# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module Extensions
    # Adds type-casting behavior to FalseClass.
    module FalseClass
      # Get the value of the object as a mongo friendly sort value.
      #
      # @example Get the object as sort criteria.
      #   object.__sortable__
      #
      # @return [ Integer ] 0.
      # @deprecated
      def __sortable__
        0
      end
      Mongoid.deprecate(self, :__sortable__)

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

FalseClass.include Mongoid::Extensions::FalseClass
