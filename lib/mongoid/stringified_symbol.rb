# frozen_string_literal: true

# A class which sends values to the database as Strings but returns them to the user as Symbols.
module Mongoid
  class StringifiedSymbol

    class << self

      # Convert the object from its mongo friendly ruby type to this type.
      #
      # @example Demongoize the object.
      #   Mongoid::StringifiedSymbol.demongoize(object)
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

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   Mongoid::StringifiedSymbol.mongoize("123.11")
      #
      # @param [ Object ] object The object to mongoize.
      #
      # @return [ Symbol ] The object mongoized.
      #
      # @api private
      def mongoize(object)
         if object.nil?
           object
         else
           object.to_s
         end
      end

      # @api private
      def evolve(object)
        mongoize(object)
      end
    end
  end
end
