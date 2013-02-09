# encoding: utf-8
module Mongoid
  module Contextual
    class GeoNear
      include Enumerable
      include Command

      delegate :[], to: :results
      delegate :==, :empty?, to: :entries

      # Get the average distance for all documents from the point in the
      # command.
      #
      # @example Get the average distance.
      #   geo_near.average_distance
      #
      # @return [ Float, nil ] The average distance.
      #
      # @since 3.1.0
      def average_distance
        average = stats["avgDistance"]
        average.nan? ? nil : average
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
      #
      # @since 3.1.0
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
      # @param [ Integer, Float ] value The distance multiplier.
      #
      # @return [ GeoNear ] The GeoNear wrapper.
      #
      # @since 3.1.0
      def distance_multiplier(value)
        command[:distanceMultiplier] = value
        self
      end

      # Initialize the new map/reduce directive.
      #
      # @example Initialize the new map/reduce.
      #   MapReduce.new(criteria, map, reduce)
      #
      # @param [ Criteria ] criteria The Mongoid criteria.
      # @param [ String ] map The map js function.
      # @param [ String ] reduce The reduce js function.
      #
      # @since 3.0.0
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
      #
      # @since 3.1.0
      def inspect
%Q{#<Mongoid::Contextual::GeoNear
  selector:   #{criteria.selector.inspect}
  class:      #{criteria.klass}
  near:       #{command[:near]}
  multiplier: #{command[:distanceMultiplier] || "N/A"}
  max:        #{command[:maxDistance] || "N/A"}
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
      # @param [ Integer, Float ] value The maximum distance.
      #
      # @return [ GeoNear, Float ] The GeoNear command or the value.
      #
      # @since 3.1.0
      def max_distance(value = nil)
        if value
          command[:maxDistance] = value
          self
        else
          stats["maxDistance"]
        end
      end

      # Tell the command to calculate based on spherical distances.
      #
      # @example Add the spherical flag.
      #   geo_near.spherical
      #
      # @return [ GeoNear ] The command.
      #
      # @since 3.1.0
      def spherical
        command[:spherical] = true
        self
      end

      # Tell the command whether or not the retured results should be unique.
      #
      # @example Set the unique flag.
      #   geo_near.unique(false)
      #
      # @param [ true, false ] value Whether to return unique documents.
      #
      # @return [ GeoNear ] The command.
      #
      # @since 3.1.0
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
      #
      # @since 3.1.0
      def execute
        results
      end

      # Get the stats for the command run.
      #
      # @example Get the stats.
      #   geo_near.stats
      #
      # @return [ Hash ] The stats from the command run.
      #
      # @since 3.1.0
      def stats
        results["stats"]
      end

      # Get the execution time of the command.
      #
      # @example Get the execution time.
      #   geo_near.time
      #
      # @return [ Float ] The execution time.
      #
      # @since 3.1.0
      def time
        stats["time"]
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
      #
      # @since 3.0.0
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
      # @return [ Array, Cursor ] The documents.
      #
      # @since 3.0.0
      def documents
        results["results"].map do |attributes|
          doc = Factory.from_db(criteria.klass, attributes["obj"], criteria.object_id)
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
      #
      # @since 3.0.0
      def results
        @results ||= session.command(command)
      end
    end
  end
end

