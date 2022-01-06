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
        if Mongoid.map_big_decimal_to_decimal128
          BSON::Decimal128.new(self)
        else
          to_s
        end
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
          if object
            if object.is_a?(BSON::Decimal128)
              demongoize_from_decimal128(object)
            elsif object.numeric?
              BigDecimal(object.to_s) # TODO: this should be a ::BigDecimal
            end
          end
        end

        # Mongoize an object of any type to how it's stored in the db as a String.
        #
        # @example Mongoize the object.
        #   BigDecimal.mongoize(123)
        #
        # @param [ Object ] object The object to Mongoize
        #
        # @return [ String, nil ] A String representing the object or nil.
        def mongoize(object)
          if object
            if Mongoid.map_big_decimal_to_decimal128
              mongoize_to_decimal128(object)
            elsif object.numeric?
              object.to_s
            end
          end
        end

        private

        def demongoize_from_decimal128(object)
          if Mongoid.map_big_decimal_to_decimal128
            object.to_big_decimal
          else
            raise Mongoid::Errors::UnmappedBSONType.new(object)
          end
        end

        def mongoize_to_decimal128(object)
          if object.is_a?(BigDecimal)
            BSON::Decimal128.new(object)
          elsif object.numeric?
            BSON::Decimal128.new(object.to_s)
          end
        end
      end
    end
  end
end

::BigDecimal.__send__(:include, Mongoid::Extensions::BigDecimal)
::BigDecimal.extend(Mongoid::Extensions::BigDecimal::ClassMethods)
