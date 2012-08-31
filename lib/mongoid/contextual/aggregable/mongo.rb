# encoding: utf-8
module Mongoid
  module Contextual
    module Aggregable
      # Contains behaviour for aggregating values in Mongo.
      module Mongo

        # Get all the aggregate values for the provided field.
        #
        # @example Get all the aggregate values.
        #   aggregable.aggregates(:likes)
        #
        # @param [ String, Symbol ] field The field name.
        #
        # @return [ Hash ] The aggregate values in the form:
        #   {
        #     "count" => 2.0,
        #     "max" => 1000.0,
        #     "min" => 500.0,
        #     "sum" => 1500.0,
        #     "avg" => 750.0
        #   }
        #
        # @since 3.0.0
        def aggregates(field)
          if query.count > 0
            map_reduce(mapper(field), reducer).
              out(inline: 1).finalize(finalizer).first["value"]
          else
            { "count" => 0 }
          end
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
          aggregates(field)["avg"]
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
          block_given? ? super() : aggregates(field)["max"]
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
          block_given? ? super() : aggregates(field)["min"]
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
          block_given? ? super() : aggregates(field)["sum"]
        end

        private

        # Get the finalize function.
        #
        # @api private
        #
        # @example Get the finalize function.
        #   aggregable.finalizer
        #
        # @return [ String ] The finalize JS function.
        #
        # @since 3.0.0
        def finalizer
          %Q{
          function(key, agg) {
            agg.avg = agg.sum / agg.count;
            return agg;
          }}
        end

        # Get the map function for the provided field.
        #
        # @api private
        #
        # @example Get the map function.
        #   aggregable.mapper(:likes)
        #
        # @param [ String, Symbol ] field The name of the field.
        #
        # @return [ String ] The map JS function.
        #
        # @since 3.0.0
        def mapper(field)
          %Q{
          function() {
            var agg = {
              count: 1,
              max: this.#{field},
              min: this.#{field},
              sum: this.#{field}
            };
            emit("#{field}", agg);
          }}
        end

        # Get the reduce function for the provided field.
        #
        # @api private
        #
        # @example Get the reduce function.
        #   aggregable.reducer(:likes)
        #
        # @return [ String ] The reduce JS function.
        #
        # @since 3.0.0
        def reducer
          %Q{
          function(key, values) {
            var agg = { count: 0, max: null, min: null, sum: 0 };
            values.forEach(function(val) {
              if (val.max !== null) {
                if (agg.max == null || val.max > agg.max) agg.max = val.max;
                if (agg.min == null || val.max < agg.min) agg.min = val.max;
                agg.sum += val.sum;
              }
              agg.count += 1;
            });
            return agg;
          }}
        end
      end
    end
  end
end
