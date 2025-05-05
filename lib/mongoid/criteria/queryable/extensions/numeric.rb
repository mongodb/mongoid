# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  class Criteria
    module Queryable
      module Extensions

        # Adds query type-casting behavior to Numeric module and its children.
        module Numeric

          # Evolve the numeric value into a mongo friendly date, aka UTC time at
          # midnight.
          #
          # @example Evolve to a date.
          #   125214512412.1123.__evolve_date__
          #
          # @return [ Time ] The time representation at UTC midnight.
          def __evolve_date__
            time = ::Time.at(self).utc
            ::Time.utc(time.year, time.month, time.day, 0, 0, 0, 0)
          end

          # Evolve the numeric value into a mongo friendly time.
          #
          # @example Evolve to a time.
          #   125214512412.1123.__evolve_time__
          #
          # @return [ Time ] The time representation.
          def __evolve_time__
            ::Time.at(self).utc
          end

          module ClassMethods

            # Evolve the object to an integer.
            #
            # @example Evolve to integers.
            #   Integer.evolve("1")
            #
            # @param [ Object ] object The object to evolve.
            #
            # @return [ Integer ] The evolved object.
            def evolve(object)
              __evolve__(object) do |obj|
                str = obj.to_s
                if str.empty?
                  nil
                else
                  # These requirements seem a bit odd, but they're explicitly specified
                  # in the tests, so we're obligated to keep them, for now.
                  str = str.chop if str.end_with?('.')
                  if str.empty?
                    0
                  else
                    result = Integer(str) rescue Float(obj)
                    integer = result.to_i
                    integer == result ? integer : result
                  end
                end
              rescue
                obj
              end
            end
          end
        end
      end
    end
  end
end

::Integer.__send__(:include, Mongoid::Criteria::Queryable::Extensions::Numeric)
::Integer.__send__(:extend, Mongoid::Criteria::Queryable::Extensions::Numeric::ClassMethods)

::Float.__send__(:include, Mongoid::Criteria::Queryable::Extensions::Numeric)
::Float.__send__(:extend, Mongoid::Criteria::Queryable::Extensions::Numeric::ClassMethods)
