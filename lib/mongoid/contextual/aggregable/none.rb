# frozen_string_literal: true

module Mongoid
  module Contextual
    module Aggregable
      # Contains behavior for aggregating values in null context.
      module None
        AGGREGATES = { "count" => 0, "sum" => 0, "avg" => nil, "min" => nil, "max" => nil }.freeze

        # Get all the aggregate values for the provided field in null context.
        # Provided for interface consistency with Aggregable::Mongo.
        #
        # @param [ String, Symbol ] _field The field name.
        #
        # @return [ Hash ] A Hash with count, sum of 0 and max, min, avg of nil.
        def aggregates(_field)
          AGGREGATES.dup
        end

        # Always returns zero.
        #
        # @example Get the sum of null context.
        #
        # @param [ Symbol ] _field The field to sum.
        #
        # @return [ Integer ] Always zero.
        def sum(_field = nil)
          0
        end

        # Always returns nil.
        #
        # @example Get the avg of null context.
        #
        # @param [ Symbol ] _field The field to avg.
        #
        # @return [ nil ] Always nil.
        def avg(_field)
          nil
        end

        # Always returns nil.
        #
        # @example Get the min of null context.
        #
        # @param [ Symbol ] _field The field to min.
        #
        # @return [ nil ] Always nil.
        def min(_field = nil)
          nil
        end

        # Always returns nil.
        #
        # @example Get the max of null context.
        #
        # @param [ Symbol ] _field The field to max.
        #
        # @return [ nil ] Always nil.
        alias :max :min
      end
    end
  end
end
