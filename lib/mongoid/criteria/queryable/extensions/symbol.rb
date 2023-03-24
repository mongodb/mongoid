# frozen_string_literal: true

module Mongoid
  class Criteria
    module Queryable
      module Extensions

        # This module contains additional symbol behavior.
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

            # Adds a method on symbol as a convenience for the MongoDB operator.
            #
            # @example Add the $in method.
            #   Symbol.add_key(:in, "$in")
            #
            # @param [ Symbol ] name The name of the method.
            # @param [ Symbol ] strategy The name of the merge strategy.
            # @param [ String ] operator The MongoDB operator.
            # @param [ String ] additional The additional MongoDB operator.
            def add_key(name, strategy, operator, additional = nil, &block)
              define_method(name) do
                method = "__#{strategy}__".to_sym
                Key.new(self, method, operator, additional, &block)
              end
            end

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
