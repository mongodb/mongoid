# frozen_string_literal: true
# rubocop:todo all

require "mongoid/contextual/aggregable"

module Mongoid
  module Contextual
    module Aggregable
      # Contains behavior for aggregating values in Mongo.
      module Mongo

        # Get all the aggregate values for the provided field.
        #
        # @example Get all the aggregate values.
        #   aggregable.aggregates(:likes)
        #   # => {
        #   #   "count" => 2.0,
        #   #   "max" => 1000.0,
        #   #   "min" => 500.0,
        #   #   "sum" => 1500.0,
        #   #   "avg" => 750.0
        #   # }
        #
        # @param [ String | Symbol ] field The field name.
        #
        # @return [ Hash ] A Hash containing the aggregate values.
        #   If no documents are found, then returned Hash will have
        #   count, sum of 0 and max, min, avg of nil.
        # @deprecated
        def aggregates(field)
          result = collection.aggregate(pipeline(field), session: _session).to_a
          if result.empty?
            Aggregable::EMPTY_RESULT.dup
          else
            result.first
          end
        end
        Mongoid.deprecate(self, :aggregates)

        # Get the average value of the provided field.
        #
        # @example Get the average of a single field.
        #   aggregable.avg(:likes)
        #
        # @param [ Symbol ] field The field to average.
        #
        # @return [ Float ] The average.
        # @deprecated
        def avg(field)
          aggregates(field)["avg"]
        end
        Mongoid.deprecate(self, :avg)

        # Get the max value of the provided field. If provided a block, will
        # return the Document with the greatest value for the field, in
        # accordance with Ruby's enumerable API.
        #
        # @example Get the max of a single field.
        #   aggregable.max(:likes)
        #
        # @example Get the document with the max value.
        #   aggregable.max do |a, b|
        #     a.likes <=> b.likes
        #   end
        #
        # @param [ Symbol ] field The field to max.
        #
        # @return [ Float | Document ] The max value or document with the max
        #   value.
        # @deprecated
        def max(field = nil)
          block_given? ? super() : aggregates(field)["max"]
        end
        Mongoid.deprecate(self, :max)

        # Get the min value of the provided field. If provided a block, will
        # return the Document with the smallest value for the field, in
        # accordance with Ruby's enumerable API.
        #
        # @example Get the min of a single field.
        #   aggregable.min(:likes)
        #
        # @example Get the document with the min value.
        #   aggregable.min do |a, b|
        #     a.likes <=> b.likes
        #   end
        #
        # @param [ Symbol ] field The field to min.
        #
        # @return [ Float | Document ] The min value or document with the min
        #   value.
        # @deprecated
        def min(field = nil)
          block_given? ? super() : aggregates(field)["min"]
        end
        Mongoid.deprecate(self, :min)

        # Get the sum value of the provided field. If provided a block, will
        # return the sum in accordance with Ruby's enumerable API.
        #
        # @example Get the sum of a single field.
        #   aggregable.sum(:likes)
        #
        # @example Get the sum for the provided block.
        #   aggregable.sum(&:likes)
        #
        # @param [ Symbol ] field The field to sum.
        #
        # @return [ Float ] The sum value.
        # @deprecated
        def sum(field = nil)
          block_given? ? super() : aggregates(field)["sum"] || 0
        end
        Mongoid.deprecate(self, :sum)

        private

        # Get the aggregation pipeline for provided field.
        #
        # @api private
        #
        # @example Get the pipeline.
        #   aggregable.pipeline(:likes)
        #
        # @param [ String | Symbol ] field The name of the field.
        #
        # @return [ Array ] The array of pipeline operators.
        def pipeline(field)
          db_field = "$#{database_field_name(field)}"
          sort, skip, limit = criteria.options.values_at(:sort, :skip, :limit)

          pipeline = []
          pipeline << { "$match" =>  criteria.exists(field => true).selector }
          pipeline << { "$sort" => sort } if sort && (skip || limit)
          pipeline << { "$skip" => skip } if skip
          pipeline << { "$limit" => limit } if limit
          pipeline << {
            "$group"  => {
              "_id"   => field.to_s,
              "count" => { "$sum" => 1 },
              "max"   => { "$max" => db_field },
              "min"   => { "$min" => db_field },
              "sum"   => { "$sum" => db_field },
              "avg"   => { "$avg" => db_field }
            }
          }
        end
      end
    end
  end
end
