# frozen_string_literal: true

module Mongoid
  module Extensions
    module Binary

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   object.mongoize
      #
      # @return [ Object ] The object.
      def mongoize
        BSON::Binary.mongoize(self)
      end

      module ClassMethods

        # Mongoize an object of any type to how it's stored in the db.
        #
        # @example Mongoize the object.
        #   BigDecimal.mongoize(123)
        #
        # @param [ Object ] object The object to Mongoize
        #
        # @return [ String | Symbol | BSON::Binary | nil ] A String or Binary
        #   representing the object or nil.
        def mongoize(object)
          wrap_mongoize(object) do
            case object
            when BSON::Binary
              object
            when String, Symbol
              BSON::Binary.new(object.to_s)
            end
          end
        end
      end
    end
  end
end

BSON::Binary.__send__(:include, Mongoid::Extensions::Binary)
BSON::Binary.extend(Mongoid::Extensions::Binary::ClassMethods)
