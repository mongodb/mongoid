# frozen_string_literal: true
# rubocop:todo all

module Mongoid

  # A class which sends values to the database as Strings but returns
  # them to the user as Symbols.
  class StringifiedSymbol

    class << self

      # Convert the object from its mongo friendly ruby type to this type.
      #
      # @example Demongoize the object.
      #   Mongoid::StringifiedSymbol.demongoize('hedgehog')
      #
      # @param [ Object ] object The object to demongoize.
      #
      # @return [ Symbol ] The object.
      #
      # @api private
      def demongoize(object)
        if object.nil?
          object
        else
          object.to_s.to_sym
        end
      end

      # Turn the object from the Ruby type into the type
      # type used for MongoDB persistence.
      #
      # @example Mongoize the object.
      #   Mongoid::StringifiedSymbol.mongoize(:hedgehog)
      #
      # @param [ Object ] object The object to mongoize.
      #
      # @return [ String ] The object mongoized.
      #
      # @api private
      def mongoize(object)
         if object.nil?
           object
         else
           object.to_s
         end
      end

      # Turn the object from the Ruby type into the type
      # type used in MQL queries.
      #
      # @example Evolve the object.
      #   Mongoid::StringifiedSymbol.evolve(:hedgehog)
      #
      # @param [ Object ] object The object to evolve.
      #
      # @return [ String ] The object evolved.
      #
      # @api private
      def evolve(object)
        mongoize(object)
      end
    end
  end
end
