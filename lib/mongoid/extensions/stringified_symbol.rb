# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  class StringifiedSymbol

    class << self

      # Convert the object from its mongo friendly ruby type to this type.
      #
      # @example Demongoize the object.
      #   Symbol.demongoize(object)
      #
      # @param [ Object ] object The object to demongoize.
      #
      # @return [ Symbol ] The object.
      def demongoize(object)
        object.try(:to_sym)
      end

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   Symbol.mongoize("123.11")
      #
      # @param [ Object ] object The object to mongoize.
      #
      # @return [ Symbol ] The object mongoized.
      def mongoize(object)
        object.try(:to_s)
      end

      def evolve(object)
        mongoize(object)
      end
    end
  end
end
