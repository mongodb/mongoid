# frozen_string_literal: true

module Mongoid
  module Extensions
    module BigDecimal

      # Convert the big decimal to an $inc-able value.
      #
      # @example Convert the big decimal.
      #   bd.__to_inc__
      #
      # @return [ Float ] The big decimal as a float.
      def __to_inc__
        to_f
      end

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   object.mongoize
      #
      # @return [ Object ] The object.
      def mongoize
        ::BigDecimal.mongoize(self)
      end

      # Is the BigDecimal a number?
      #
      # @example Is the object a number?.
      #   object.numeric?
      #
      # @return [ true ] Always true.
      def numeric?
        true
      end

      module ClassMethods

        # Convert the object from its mongo friendly ruby type to this type.
        #
        # @example Demongoize the object.
        #   Object.demongoize(object)
        #
        # @param [ Object ] object The object to demongoize.
        #
        # @return [ BigDecimal, nil ] A BigDecimal derived from the object or nil.
        def demongoize(object)
          unless object.nil?
            if object.is_a?(BSON::Decimal128)
              object.to_big_decimal
            elsif object.numeric?
              BigDecimal(object.to_s)
            end
          end
        end

        # Mongoize an object of any type to how it's stored in the db.
        #
        # @example Mongoize the object.
        #   BigDecimal.mongoize(123)
        #
        # @param [ Object ] object The object to Mongoize
        #
        # @return [ String | BSON::Decimal128 | nil ] A String or Decimal128
        #   representing the object or nil.
        def mongoize(object)
          wrap_mongoize(object) do
            if object.is_a?(BSON::Decimal128)
              object
            elsif Mongoid.map_big_decimal_to_decimal128
              if object.is_a?(BigDecimal)
                BSON::Decimal128.new(object)
              elsif object.numeric?
                ::BSON::Decimal128.new(object.to_s)
              end
            elsif object.numeric?
              object.to_s
            end
          end
        end
      end
    end
  end
end

::BigDecimal.__send__(:include, Mongoid::Extensions::BigDecimal)
::BigDecimal.extend(Mongoid::Extensions::BigDecimal::ClassMethods)
