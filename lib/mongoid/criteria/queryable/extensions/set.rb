# frozen_string_literal: true

require "set"

module Mongoid
  class Criteria
    module Queryable
      module Extensions

        # This module contains additional object behavior.
        module Set
          module ClassMethods

            # Evolve the set, casting all its elements.
            #
            # @example Evolve the set.
            #   Set.evolve(set)
            #
            # @param [ Set | Object ] object The object to evolve.
            #
            # @return [ Array ] The evolved set.
            def evolve(object)
              return object if !object || !object.respond_to?(:map)
              object.map{ |obj| obj.class.evolve(obj) }
            end
          end
        end
      end
    end
  end
end

::Set.__send__(:extend, Mongoid::Criteria::Queryable::Extensions::Set::ClassMethods)
