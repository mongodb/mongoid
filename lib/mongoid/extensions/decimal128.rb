# frozen_string_literal: true

module Mongoid
  module Extensions
    module Decimal128

      # Evolve the decimal128.
      #
      # @example Evolve the decimal128.
      #   decimal128.__evolve_decimal128__
      #
      # @return [ BSON::Decimal128 ] self.
      def __evolve_decimal128__
        self
      end

      module ClassMethods

        # Evolve the object into a mongo-friendly value to query with.
        #
        # @example Evolve the object.
        #   Decimal128.evolve(dec)
        #
        # @param [ Object ] object The object to evolve.
        #
        # @return [ BSON::Decimal128 ] The decimal128.
        def evolve(object)
          object.__evolve_decimal128__
        end
      end
    end
  end
end

BSON::Decimal128.__send__(:include, Mongoid::Extensions::Decimal128)
BSON::Decimal128.extend(Mongoid::Extensions::Decimal128::ClassMethods)
