# frozen_string_literal: true
# rubocop:todo all

require "mongoid/contextual/aggregable"

module Mongoid
  module Contextual
    module Aggregable
      # Contains behavior for aggregating values in null context.
      module None

        # Get all the aggregate values for the provided field in null context.
        # Provided for interface consistency with Aggregable::Mongo.
        #
        # @param [ String | Symbol ] _field The field name.
        #
        # @return [ Hash ] A Hash with count, sum of 0 and max, min, avg of nil.
        # @deprecated
        def aggregates(_field)
          Aggregable::EMPTY_RESULT.dup
        end
        Mongoid.deprecate(self, :aggregates)

        # Always returns zero.
        #
        # @example Get the sum of null context.
        #
        # @param [ Symbol ] _field The field to sum.
        #
        # @return [ Integer ] Always zero.
        # @deprecated
        def sum(_field = nil)
          0
        end
        Mongoid.deprecate(self, :sum)

        # Always returns nil.
        #
        # @example Get the avg of null context.
        #
        # @param [ Symbol ] _field The field to avg.
        #
        # @return [ nil ] Always nil.
        # @deprecated
        def avg(_field)
          nil
        end
        Mongoid.deprecate(self, :avg)

        # Always returns nil.
        #
        # @example Get the min of null context.
        #
        # @param [ Symbol ] _field The field to min.
        #
        # @return [ nil ] Always nil.
        # @deprecated
        def min(_field = nil)
          nil
        end
        Mongoid.deprecate(self, :min)

        # Always returns nil.
        #
        # @example Get the max of null context.
        #
        # @param [ Symbol ] _field The field to max.
        #
        # @return [ nil ] Always nil.
        # @deprecated
        alias :max :min
        Mongoid.deprecate(self, :max)
      end
    end
  end
end
