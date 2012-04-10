# encoding: utf-8
module Mongoid #:nodoc:
  module Contextual
    module Aggregable
      # Contains behaviour for aggregating values in memory.
      module Memory

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
          count > 0 ? sum(field) / count : nil
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
          if block_given?
            super()
          else
            count > 0 ? max_by { |doc| doc.send(field) }.send(field) : nil
          end
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
          if block_given?
            super()
          else
            count > 0 ? min_by { |doc| doc.send(field) }.send(field) : nil
          end
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
          if block_given?
            super()
          else
            count > 0 ? super(0) { |doc| doc.send(field) } : nil
          end
        end
      end
    end
  end
end
