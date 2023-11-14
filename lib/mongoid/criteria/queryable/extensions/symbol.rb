# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  class Criteria
    module Queryable
      module Extensions

        # Adds query type-casting behavior to Symbol class.
        module Symbol

          # Get the symbol as a specification.
          #
          # @example Get the symbol as a criteria.
          #   :field.__expr_part__(value)
          #
          # @param [ Object ] value The value of the criteria.
          # @param [ true | false ] negating If the selection should be negated.
          #
          # @return [ Hash ] The selection.
          def __expr_part__(value, negating = false)
            ::String.__expr_part__(self, value, negating)
          end

          module ClassMethods

            # Evolves the symbol into a MongoDB friendly value - in this case
            # a symbol.
            #
            # @example Evolve the symbol
            #   Symbol.evolve("test")
            #
            # @param [ Object ] object The object to convert.
            #
            # @return [ Symbol ] The value as a symbol.
            def evolve(object)
              __evolve__(object) do |obj|
                obj.try(:to_sym)
              end
            end
          end
        end
      end
    end
  end
end

::Symbol.__send__(:include, Mongoid::Criteria::Queryable::Extensions::Symbol)
::Symbol.__send__(:extend, Mongoid::Criteria::Queryable::Extensions::Symbol::ClassMethods)
