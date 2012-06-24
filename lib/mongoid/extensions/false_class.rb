# encoding: utf-8
module Mongoid
  module Extensions
    module FalseClass

      # Get the value of the object as a mongo friendy sort value.
      #
      # @example Get the object as sort criteria.
      #   object.__sortable__
      #
      # @return [ Integer ] 0.
      #
      # @since 3.0.0
      def __sortable__
        0
      end

      # Is the passed value a boolean?
      #
      # @example Is the value a boolean type?
      #   false.is_a?(Boolean)
      #
      # @param [ Class ] other The class to check.
      #
      # @return [ true, false ] If the other is a boolean.
      #
      # @since 1.0.0
      def is_a?(other)
        if other == ::Boolean || other.class == ::Boolean
          return true
        end
        super(other)
      end
    end
  end
end

::FalseClass.__send__(:include, Mongoid::Extensions::FalseClass)
