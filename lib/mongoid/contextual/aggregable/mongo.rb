# frozen_string_literal: true

require "mongoid/contextual/aggregable/none"

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
        # @param [ String, Symbol ] field The field name.
        # @param [ Array<String|Symbol> ] operators The aggregable operations to perform.
        #
        # @return [ Integer | Float | Hash ] A Hash containing the aggregate values.
        #   If a single operator is specified, the aggregate value for the given
        #   operator only will be returned.
        #
        # @since 3.0.0
        def aggregates(field, *operators)
          result = collection.find.aggregate(pipeline(field, *operators), session: _session).to_a.first
          result ||= Mongoid::Contextual::Aggregable::None::AGGREGATES.dup
          result.size == 1 ? result.values.first : result
        end

        # Get the average value of the provided field.
        #
        # @example Get the average of a single field.
        #   aggregable.avg(:likes)
        #
        # @param [ Symbol ] field The field to average.
        #
        # @return [ Float ] The average.
        #
        # @since 3.0.0
        def avg(field)
          aggregates(field, 'avg')
        end

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
        # @return [ Float, Document ] The max value or document with the max
        #   value.
        #
        # @since 3.0.0
        def max(field = nil)
          block_given? ? super() : aggregates(field, 'max')
        end

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
        # @return [ Float, Document ] The min value or document with the min
        #   value.
        #
        # @since 3.0.0
        def min(field = nil)
          block_given? ? super() : aggregates(field, 'min')
        end

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
        #
        # @since 3.0.0
        def sum(field = nil)
          block_given? ? super() : aggregates(field, 'sum') || 0
        end

        private

        # Get the aggregation pipeline for provided field.
        #
        # @api private
        #
        # @example Get the pipeline.
        #   aggregable.pipeline(:likes)
        #
        # @param [ String, Symbol ] field The name of the field.
        # @param [ Array<String|Symbol> ] operators The aggregable operations to perform.
        #
        # @return [ Array ] The array of pipeline operators.
        #
        # @since 3.1.0
        def pipeline(field, *operators)
          operators = operators.map(&:to_s)
          db_field = "$#{database_field_name(field)}"
          pipeline = []
          pipeline << { "$match" =>  criteria.exists(field => true).selector }
          pipeline << { "$sort" => criteria.options[:sort] } if criteria.options[:sort]
          pipeline << { "$skip" => criteria.options[:skip] } if criteria.options[:skip]
          pipeline << { "$limit" => criteria.options[:limit] } if criteria.options[:limit]
          group = {
            "count" => { "$sum" => 1 },
            "max"   => { "$max" => db_field },
            "min"   => { "$min" => db_field },
            "sum"   => { "$sum" => db_field },
            "avg"   => { "$avg" => db_field }
          }
          group.slice!(*operators) if (operators & group.keys).present?
          pipeline << { "$group" => { "_id" => field.to_s }.merge!(group) }
        end
      end
    end
  end
end
