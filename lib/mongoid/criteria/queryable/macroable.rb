# frozen_string_literal: true

module Mongoid
  class Criteria
    module Queryable

      # Adds macro behavior for adding symbol methods.
      module Macroable

        # Adds a method on Symbol for convenience in where queries for the
        # provided operators.
        #
        # @example Add a symbol key.
        #   key :all, "$all
        #
        # @param [ Symbol ] name The name of the method.
        # @param [ Symbol ] strategy The merge strategy.
        # @param [ String ] operator The MongoDB operator.
        # @param [ String ] additional The additional MongoDB operator.
        def key(name, strategy, operator, additional = nil, &block)
          ::Symbol.add_key(name, strategy, operator, additional, &block)
        end
      end
    end
  end
end
