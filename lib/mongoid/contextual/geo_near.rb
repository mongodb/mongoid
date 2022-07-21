# frozen_string_literal: true

module Mongoid
  module Contextual
    class GeoNear
      extend Forwardable
      include Enumerable
      include Command

      def_delegator :results, :[]
      def_delegators :entries, :==, :empty?

      # Get the average distance for all documents from the point in the
      # command.
      #
      # @example Get the average distance.
      #   geo_near.average_distance
      #
      # @return [ Float | nil ] The average distance.
      def average_distance
        average = stats["avgDistance"]
        (average.nil? || average.nan?) ? nil : average
      end

      # Iterates over each of the documents in the $geoNear, excluding the
      # extra information that was passed back from the database.
      #
      # @example Iterate over the results.
      #   geo_near.each do |doc|
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

      # Provide a distance multiplier to be used for each returned distance.
      #
      # @example Provide the distance multiplier.
      #   geo_near.distance_multiplier(13113.1)
      #
      # @param [ Integer | Float ] value The distance multiplier.
      #
      # @return [ GeoNear ] The GeoNear wrapper.
      def distance_multiplier(value)
        command[:distanceMultiplier] = value
        self
      end

      # Initialize the new map/reduce directive.
      #
      # @example Initialize the new map/reduce.
      #   MapReduce.new(criteria, map, reduce)
      #
      # @param [ Mongo::Collection ] collection The collection to run the
      #   operation on.
      # @param [ Criteria ] criteria The Mongoid criteria.
      # @param [ String ] near
      def initialize(collection, criteria, near)
        @collection, @criteria = collection, criteria
        command[:geoNear] = collection.name.to_s
        command[:near] = near
        apply_criteria_options
      end

      # Get a pretty string representation of the command.
      #
      # @example Inspect the geoNear.
      #   geo_near.inspect
      #
      # @return [ String ] The inspection string.
      def inspect
%Q{#<Mongoid::Contextual::GeoNear
  selector:   #{criteria.selector.inspect}
  class:      #{criteria.klass}
  near:       #{command[:near]}
  multiplier: #{command[:distanceMultiplier] || "N/A"}
  max:        #{command[:maxDistance] || "N/A"}
  min:        #{command[:minDistance] || "N/A"}
  unique:     #{command[:unique].nil? ? true : command[:unique]}
  spherical:  #{command[:spherical] || false}>
}
      end

      # Specify the maximum distance to find documents for, or get the value of
      # the document with the furthest distance.
      #
      # @example Set the max distance.
      #   geo_near.max_distance(0.5)
      #
      # @example Get the max distance.
      #   geo_near.max_distance
      #
      # @param [ Integer | Float ] value The maximum distance.
      #
      # @return [ GeoNear | Float ] The GeoNear command or the value.
      def max_distance(value = nil)
        if value
          command[:maxDistance] = value
          self
        else
          stats["maxDistance"]
        end
      end

      # Specify the minimum distance to find documents for.
      #
      # @example Set the min distance.
      #   geo_near.min_distance(0.5)
      #
      # @param [ Integer | Float ] value The minimum distance.
      #
      # @return [ GeoNear ] The GeoNear command.
      def min_distance(value)
        command[:minDistance] = value
        self
      end

      # Tell the command to calculate based on spherical distances.
      #
      # @example Add the spherical flag.
      #   geo_near.spherical
      #
      # @return [ GeoNear ] The command.
      def spherical
        command[:spherical] = true
        self
      end

      # Tell the command whether or not the returned results should be unique.
      #
      # @example Set the unique flag.
      #   geo_near.unique(false)
      #
      # @param [ true | false ] value Whether to return unique documents.
      #
      # @return [ GeoNear ] The command.
      def unique(value = true)
        command[:unique] = value
        self
      end

      # Execute the $geoNear, returning the raw output.
      #
      # @example Run the $geoNear
      #   geo_near.execute
      #
      # @return [ Hash ] The raw output
      def execute
        results
      end

      # Get the stats for the command run.
      #
      # @example Get the stats.
      #   geo_near.stats
      #
      # @return [ Hash ] The stats from the command run.
      def stats
        results["stats"]
      end

      # Get the execution time of the command.
      #
      # @example Get the execution time.
      #   geo_near.time
      #
      # @return [ Float ] The execution time.
      def time
        stats["time"]
      end

      # Is this context's criteria considered empty?
      #
      # @example Is this context's criteria considered empty?
      #   geo_near.empty_and_chainable?
      #
      # @return [ true ] Always true.
      def empty_and_chainable?
        true
      end

      private

      # Apply criteria specific options - query, limit.
      #
      # @api private
      #
      # @example Apply the criteria options
      #   geo_near.apply_criteria_options
      #
      # @return [ nil ] Nothing.
      def apply_criteria_options
        command[:query] = criteria.selector
        if limit = criteria.options[:limit]
          command[:num] = limit
        end
      end

      # Get the result documents from the $geoNear.
      #
      # @api private
      #
      # @example Get the documents.
      #   geo_near.documents
      #
      # @return [ Array | Cursor ] The documents.
      def documents
        results["results"].map do |attributes|
          doc = Factory.from_db(criteria.klass, attributes["obj"], criteria)
          doc.attributes["geo_near_distance"] = attributes["dis"]
          doc
        end
      end

      # Execute the $geoNear command and get the results.
      #
      # @api private
      #
      # @example Get the results.
      #   geo_near.results
      #
      # @return [ Hash ] The results of the command.
      def results
        @results ||= client.command(command).first
      end
    end
  end
end
