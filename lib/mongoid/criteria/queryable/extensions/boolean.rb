# frozen_string_literal: true
# encoding: utf-8

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
            #
            # @since 1.0.0
            def evolve(object)
              __evolve__(object) do |obj|
                obj.to_s =~ (/\A(true|t|yes|y|on|1|1.0)\z/i) ? true : false
              end
            end
          end
        end
      end
    end
  end
end

::Boolean.__send__(:extend, Mongoid::Criteria::Queryable::Extensions::Boolean::ClassMethods)
