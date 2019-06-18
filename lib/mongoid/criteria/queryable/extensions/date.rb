# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  class Criteria
    module Queryable
      module Extensions

        # This module contains additional date behavior.
        module Date

          # Evolve the date into a mongo friendly time, UTC midnight.
          #
          # @example Evolve the date.
          #   date.__evolve_date__
          #
          # @return [ Time ] The date as a UTC time at midnight.
          #
          # @since 1.0.0
          def __evolve_date__
            ::Time.utc(year, month, day, 0, 0, 0, 0)
          end

          # Evolve the date into a time, which is always in the local timezone.
          #
          # @example Evolve the date.
          #   date.__evolve_time__
          #
          # @return [ Time ] The date as a local time.
          #
          # @since 1.0.0
          def __evolve_time__
            ::Time.local(year, month, day)
          end

          module ClassMethods

            # Evolve the object to an date.
            #
            # @example Evolve dates.
            #   Date.evolve(Date.new(1990, 1, 1))
            #
            # @example Evolve string dates.
            #   Date.evolve("1990-1-1")
            #
            # @example Evolve date ranges.
            #   Date.evolve(Date.new(1990, 1, 1)..Date.new(1990, 1, 4))
            #
            # @param [ Object ] object The object to evolve.
            #
            # @return [ Time ] The evolved date.
            #
            # @since 1.0.0
            def evolve(object)
              object.__evolve_date__
            end
          end
        end
      end
    end
  end
end

::Date.__send__(:include, Mongoid::Criteria::Queryable::Extensions::Date)
::Date.__send__(:extend, Mongoid::Criteria::Queryable::Extensions::Date::ClassMethods)
