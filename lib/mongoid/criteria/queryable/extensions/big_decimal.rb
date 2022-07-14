# frozen_string_literal: true

require "bigdecimal"

module Mongoid
  class Criteria
    module Queryable
      module Extensions

        # The big decimal module adds custom behavior for Origin onto the
        # BigDecimal class.
        module BigDecimal
          module ClassMethods

            # Evolves the big decimal into a MongoDB friendly value.
            #
            # @example Evolve the big decimal
            #   BigDecimal.evolve(decimal)
            #
            # @param [ BigDecimal ] object The object to convert.
            #
            # @return [ Object ] The big decimal as a string, a Decimal128,
            #   or the inputted object if it is uncastable.
            def evolve(object)
              __evolve__(object) do |obj|
                return if obj.nil?
                case obj
                when ::BigDecimal
                  if Mongoid.map_big_decimal_to_decimal128
                    BSON::Decimal128.new(obj)
                  else
                    obj.to_s
                  end
                # Always return on string for backwards compatibility with querying
                # string-backed BigDecimal fields.
                when BSON::Decimal128, String then obj
                else
                  if obj.numeric?
                    if Mongoid.map_big_decimal_to_decimal128
                      BSON::Decimal128.new(object.to_s)
                    else
                      obj.to_s
                    end
                  else
                    obj
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end

::BigDecimal.__send__(:extend, Mongoid::Criteria::Queryable::Extensions::BigDecimal::ClassMethods)
