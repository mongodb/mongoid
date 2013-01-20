# encoding: utf-8
module Mongoid
  module Contextual
    class Aggregation
      include Enumerable
      include Command

      delegate :[], to: :results
      delegate :==, :empty?, :count, to: :entries

      # Initialize the new aggregation directive.
      #
      # @example Initialize the aggregation.
      #   Aggregation.new(collection, criteria, pipeline)
      #
      # @param [ Collection ] collection the Mongoid collection.
      # @param [ Criteria ] criteria The Mongoid criteria.
      # @param [ Array ] pipeline The Array of pipelines.
      def initialize(collection, criteria, *pipeline)
        @collection, @criteria = collection, criteria
        command[:aggregate] = collection.name.to_s
        command[:pipeline] = pipeline.flatten
        apply_criteria_options
      end

      # Iterates over each of the documents in the aggregation, excluding the
      # extra information that was passed back from the database.
      #
      # @example Iterate over the results.
      #   aggregation.each do |doc|
      #     p doc
      #   end
      #
      # @return [ Enumerator ] The enumerator.
      def each
        if block_given?
          documents.each do |doc|
            yield doc
          end
        else
          to_enum
        end
      end

      private

      # Apply criteria specific options - query.
      #
      # @api private
      #
      # @example Apply the criteria options
      #   aggregation.apply_criteria_options
      #
      # @return [ nil ] Nothing.
      def apply_criteria_options
        command[:pipeline].unshift("$match" => criteria.selector)
      end

      # Get tje result documents from the aggregation.
      #
      # @api private
      #
      # @example Get the documents.
      #   aggregation.documents
      def documents
        results["result"]
      end

      # Execute the aggregation command and get the results.
      #
      # @api private
      #
      # @example Get the results.
      #   aggregation.results
      #
      # @return [ Hash ] The results of the command.
      def results
        @results ||= session.with(consistency: :strong).command(command)
      end
    end
  end
end
