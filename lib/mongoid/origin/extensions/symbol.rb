# encoding: utf-8
module Origin
  module Extensions

    # This module contains additional symbol behaviour.
    module Symbol

      # Get the symbol as a specification.
      #
      # @example Get the symbol as a criteria.
      #   :field.__expr_part__(value)
      #
      # @param [ Object ] value The value of the criteria.
      # @param [ true, false ] negating If the selection should be negated.
      #
      # @return [ Hash ] The selection.
      #
      # @since 1.0.0
      def __expr_part__(value, negating = false)
        ::String.__expr_part__(self, value, negating)
      end

      # Get the symbol as a sort direction.
      #
      # @example Get the symbol as a sort direction.
      #   "1".to_direction
      #
      # @return [ Integer ] The direction.
      #
      # @since 1.0.0
      def to_direction
        to_s.to_direction
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
        #
        # @since 1.0.0
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
        #
        # @since 1.0.0
        def evolve(object)
          __evolve__(object) { |obj| obj.to_sym }
        end
      end
    end
  end
end

::Symbol.__send__(:include, Origin::Extensions::Symbol)
::Symbol.__send__(:extend, Origin::Extensions::Symbol::ClassMethods)
