# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module SymbolQueryMacros
    module Extensions
      # Adds query type-casting behavior to Symbol class.
      module Symbol
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
              Key.new(self, :"__#{strategy}__", operator, additional, &block)
            end
          end
        end
      end
    end
  end
end

::Symbol.extend(Mongoid::SymbolQueryMacros::Extensions::Symbol::ClassMethods)
