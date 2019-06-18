# frozen_string_literal: true
# encoding: utf-8

require "bigdecimal"

module Mongoid
  class Criteria
    module Queryable
      module Extensions

        # The big decimal module adds custom behavior for Origin onto the
        # BigDecimal class.
        module BigDecimal
          module ClassMethods

            # Evolves the big decimal into a MongoDB friendly value - in this case
            # a string.
            #
            # @example Evolve the big decimal
            #   BigDecimal.evolve(decimal)
            #
            # @param [ BigDecimal ] object The object to convert.
            #
            # @return [ String ] The big decimal as a string.
            #
            # @since 1.0.0
            def evolve(object)
              __evolve__(object) do |obj|
                obj ? obj.to_s : obj
              end
            end
          end
        end
      end
    end
  end
end

::BigDecimal.__send__(:extend, Mongoid::Criteria::Queryable::Extensions::BigDecimal::ClassMethods)
