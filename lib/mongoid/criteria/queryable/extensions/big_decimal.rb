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
                mongoize(obj)
              end
            end
          end
        end
      end
    end
  end
end

::BigDecimal.__send__(:extend, Mongoid::Criteria::Queryable::Extensions::BigDecimal::ClassMethods)
