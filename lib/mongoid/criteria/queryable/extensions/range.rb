# frozen_string_literal: true

module Mongoid
  class Criteria
    module Queryable
      module Extensions

        # This module contains additional range behavior.
        module Range

          # Get the range as an array.
          #
          # @example Get the range as an array.
          #   1...3.__array__
          #
          # @return [ Array ] The range as an array.
          def __array__
            to_a
          end

          # Convert the range to a $gte/$lte mongo friendly query for dates.
          #
          # @example Evolve the range.
          #   (11231312..213123131).__evolve_date__
          #
          # @return [ Hash ] The $gte/$lte range query with times at UTC midnight.
          def __evolve_date__
            __evolve_range_naive__.transform_values! {|v| v&.__evolve_date__ }
          end

          # Convert the range to a $gte/$lte mongo friendly query for times.
          #
          # @example Evolve the range.
          #   (11231312..213123131).__evolve_date__
          #
          # @return [ Hash ] The $gte/$lte range query with times in UTC.
          def __evolve_time__
            __evolve_range_naive__.transform_values! {|v| v&.__evolve_time__ }
          end

          # Convert the range to a $gte/$lte mongo friendly query.
          #
          # @example Evolve the range.
          #   (11231312..213123131).__evolve_range__
          #
          # @param [ Object ] serializer The optional serializer for the field.
          #
          # @return [ Hash ] The $gte/$lte range query.
          #
          # @api private
          def __evolve_range__(serializer: nil)
            __evolve_range_naive__.transform_values! do |value|
              if serializer
                serializer.evolve(value)
              else
                case value
                when Time, DateTime then value.__evolve_time__
                when Date then value.__evolve_date__
                else value
                end
              end
            end
          end

          private

          # @note This method's return value will be mutated by the __evolve_*__
          #   methods, therefore it must always return new objects.
          #
          # @api private
          def __evolve_range_naive__
            hash = {}
            hash['$gte'] = self.begin if self.begin
            hash[exclude_end? ? "$lt" : "$lte"] = self.end if self.end
            hash
          end

          module ClassMethods

            # Evolve the range. This will transform it into a $gte/$lte selection.
            # Endless and beginning-less ranges will use only $gte or $lte respectively.
            # End-excluded ranges (...) will use $lt selector instead of $lte.
            #
            # @example Evolve the range.
            #   Range.evolve(1..3)
            #
            # @param [ Range ] object The range to evolve.
            #
            # @return [ Hash ] The range as a gte/lte criteria.
            def evolve(object)
              return object unless object.is_a?(::Range)
              object.__evolve_range__
            end
          end
        end
      end
    end
  end
end

::Range.__send__(:include, Mongoid::Criteria::Queryable::Extensions::Range)
::Range.__send__(:extend, Mongoid::Criteria::Queryable::Extensions::Range::ClassMethods)
