# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module FalseClass

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
