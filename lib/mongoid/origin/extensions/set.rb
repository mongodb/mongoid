# encoding: utf-8
require "set"

module Origin
  module Extensions

    # This module contains additional object behaviour.
    module Set
      module ClassMethods

        # Evolve the set, casting all its elements.
        #
        # @example Evolve the set.
        #   Set.evolve(set)
        #
        # @param [ Set, Object ] object The object to evolve.
        #
        # @return [ Array ] The evolved set.
        #
        # @since 1.0.0
        def evolve(object)
          return object if !object || !object.respond_to?(:map)
          object.map{ |obj| obj.class.evolve(obj) }
        end
      end
    end
  end
end

::Set.__send__(:extend, Origin::Extensions::Set::ClassMethods)
