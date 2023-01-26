# frozen_string_literal: true

module Mongoid
  module Contextual
    module Aggregable
      # Contains behavior for aggregating values in memory.
      module Memory

        # Get all the aggregate values for the provided field.
        # Provided for interface consistency with Aggregable::Mongo.
        #
        # @param [ String | Symbol ] field The field name.
        #
        # @return [ Hash ] A Hash containing the aggregate values.
        #   If no documents are present, then returned Hash will have
        #   count, sum of 0 and max, min, avg of nil.
        def aggregates(field)
          %w(count sum avg min max).each_with_object({}) do |method, hash|
            hash[method] = send(method, field)
          end
        end

        # Get the average value of the provided field.
        #
        # @example Get the average of a single field.
        #   aggregable.avg(:likes)
        #
        # @param [ Symbol ] field The field to average.
        #
        # @return [ Numeric ] The average.
        def avg(field)
          total = count { |doc| !doc.send(field).nil? }
          return nil unless total > 0

          total = total.to_f if total.is_a?(Integer)
          sum(field) / total
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
        # @return [ Numeric | Document ] The max value or document with the max
        #   value.
        def max(field = nil)
          return super() if block_given?

          aggregate_by(field, :max)
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
        # @return [ Numeric | Document ] The min value or document with the min
        #   value.
        def min(field = nil)
          return super() if block_given?

          aggregate_by(field, :min)
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
        # @return [ Numeric ] The sum value.
        def sum(field = nil)
          return super() if block_given?

          aggregate_by(field, :sum) || 0
        end

        private

        # Aggregate by the provided field and method.
        #
        # @api private
        #
        # @example Aggregate by the field and method.
        #   aggregable.aggregate_by(:likes, :min_by)
        #
        # @param [ Symbol ] field The field to aggregate on.
        # @param [ Symbol ] method The method (min_by or max_by).
        #
        # @return [ Numeric | nil ] The aggregate.
        def aggregate_by(field, method)
          return nil unless any?

          map { |doc| doc.public_send(field) }.compact.public_send(method)
        end
      end
    end
  end
end
