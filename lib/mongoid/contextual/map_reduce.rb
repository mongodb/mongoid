# frozen_string_literal: true

module Mongoid
  module Contextual
    class MapReduce
      extend Forwardable
      include Enumerable
      include Command

      def_delegators :results, :[]
      def_delegators :entries, :==, :empty?

      # Get all the counts returned by the map/reduce.
      #
      # @example Get the counts.
      #   map_reduce.counts
      #
      # @return [ Hash ] The counts.
      def counts
        results["counts"]
      end

      # Iterates over each of the documents in the map/reduce, excluding the
      # extra information that was passed back from the database.
      #
      # @example Iterate over the results.
      #   map_reduce.each do |doc|
      #     p doc
      #   end
      #
      # @return [ Enumerator ] The enumerator.
      def each
        validate_out!
        if block_given?
          @map_reduce.each do |doc|
            yield doc
          end
        else
          @map_reduce.to_enum
        end
      end

      # Get the number of documents emitted by the map/reduce.
      #
      # @example Get the emitted document count.
      #   map_reduce.emitted
      #
      # @return [ Integer ] The number of emitted documents.
      def emitted
        counts["emit"]
      end

      # Provide a finalize js function for the map/reduce.
      #
      # @example Provide a finalize function.
      #   map_reduce.finalize(func)
      #
      # @param [ String ] function The finalize function.
      #
      # @return [ MapReduce ] The map reduce.
      def finalize(function)
        @map_reduce = @map_reduce.finalize(function)
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
      def initialize(collection, criteria, map, reduce)
        @collection = collection
        @criteria = criteria
        @map_reduce = @criteria.view.map_reduce(map, reduce)
      end

      # Get the number of documents that were input into the map/reduce.
      #
      # @example Get the count of input documents.
      #   map_reduce.input
      #
      # @return [ Integer ] The number of input documents.
      def input
        counts["input"]
      end

      # Sets the map/reduce to use jsMode.
      #
      # @example Set the map/reduce to jsMode.
      #   map_reduce.js_mode
      #
      # @return [ MapReduce ] The map/reduce.
      def js_mode
        @map_reduce = @map_reduce.js_mode(true)
        self
      end

      # Specifies where the map/reduce output is to be stored.
      # Please see MongoDB documentation for supported map reduce options.
      #
      # @example Store output in memory.
      #   map_reduce.out(inline: 1)
      #
      # @example Store output in a collection, replacing existing documents.
      #   map_reduce.out(replace: "collection_name")
      #
      # @example Store output in a collection, merging existing documents.
      #   map_reduce.out(merge: "collection_name")
      #
      # @example Store output in a collection, reducing existing documents.
      #   map_reduce.out(reduce: "collection_name")
      #
      # @example Return results from map reduce.
      #   map_reduce.out(inline: 1)
      #
      # @param [ Hash ] location The place to store the results.
      #
      # @return [ MapReduce ] The map/reduce object.
      def out(location)
        normalized = location.dup
        normalized.transform_values! do |value|
          value.is_a?(::Symbol) ? value.to_s : value
        end
        @map_reduce = @map_reduce.out(normalized)
        self
      end

      # Get the number of documents output by the map/reduce.
      #
      # @example Get the output document count.
      #   map_reduce.output
      #
      # @return [ Integer ] The number of output documents.
      def output
        counts["output"]
      end

      # Get the raw output from the map/reduce operation.
      #
      # @example Get the raw output.
      #   map_reduce.raw
      #
      # @return [ Hash ] The raw output.
      def raw
        validate_out!
        cmd = command
        opts = { read: criteria.options.fetch(:read) } if criteria.options[:read]
        @map_reduce.database.command(cmd, (opts || {}).merge(session: _session)).first
      end
      alias :results :raw

      # Execute the map/reduce, returning the raw output.
      # Useful when you don't care about map/reduce's output.
      #
      # @example Run the map reduce
      #   map_reduce.execute
      #
      # @return [ Hash ] The raw output
      alias :execute :raw

      # Get the number of documents reduced by the map/reduce.
      #
      # @example Get the reduced document count.
      #   map_reduce.reduced
      #
      # @return [ Integer ] The number of reduced documents.
      def reduced
        counts["reduce"]
      end

      # Adds a javascript object to the global scope of the map/reduce.
      #
      # @example Add an object to the global scope.
      #   map_reduce.scope(name: value)
      #
      # @param [ Hash ] object A hash of key/values for the global scope.
      #
      # @return [ MapReduce ]
      def scope(object)
        @map_reduce = @map_reduce.scope(object)
        self
      end

      # Get the execution time of the map/reduce.
      #
      # @example Get the execution time.
      #   map_reduce.time
      #
      # @return [ Float ] The time in milliseconds.
      def time
        results["timeMillis"]
      end

      # Get a pretty string representation of the map/reduce, including the
      # criteria, map, reduce, finalize, and out option.
      #
      # @example Inspect the map_reduce.
      #   map_reduce.inspect
      #
      # @return [ String ] The inspection string.
      def inspect
%Q{#<Mongoid::Contextual::MapReduce
  selector: #{criteria.selector.inspect}
  class:    #{criteria.klass}
  map:      #{command[:map]}
  reduce:   #{command[:reduce]}
  finalize: #{command[:finalize]}
  out:      #{command[:out].inspect}>
}
      end

      def command
        @map_reduce.send(:map_reduce_spec)[:selector]
      end

      private

      def validate_out!
        raise Errors::NoMapReduceOutput.new({}) unless @map_reduce.out
      end

      def _session
        criteria.send(:_session)
      end
    end
  end
end
