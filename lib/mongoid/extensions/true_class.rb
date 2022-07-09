# frozen_string_literal: true

module Mongoid
  module Extensions
    module TrueClass

      # Get the value of the object as a mongo friendly sort value.
      #
      # @example Get the object as sort criteria.
      #   object.__sortable__
      #
      # @return [ Integer ] 1.
      def __sortable__
        1
      end

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
