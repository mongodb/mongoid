# frozen_string_literal: true

module Mongoid
  class Criteria
    module Queryable
      module Extensions

        # This module contains extensions for boolean selection.
        module Boolean
          module ClassMethods

            # Evolve the value into a boolean value stored in MongoDB. Will return
            # true for any of these values: true, t, yes, y, 1, 1.0.
            #
            # @example Evolve the value to a boolean.
            #   Boolean.evolve(true)
            #
            # @param [ Object ] object The object to evolve.
            #
            # @return [ true, false ] The boolean value.
            def evolve(object)
              __evolve__(object) do |obj|
                res = mongoize(object)
                res.nil? ? object : res
              end
            end
          end
        end
      end
    end
  end
end

Mongoid::Boolean.__send__(:extend, Mongoid::Criteria::Queryable::Extensions::Boolean::ClassMethods)
