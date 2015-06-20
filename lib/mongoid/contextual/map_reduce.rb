# encoding: utf-8
module Mongoid
  module Contextual
    class MapReduce
      include Enumerable
      include Command

      delegate :[], to: :results
      delegate :==, :empty?, to: :entries

      # Get all the counts returned by the map/reduce.
      #
      # @example Get the counts.
      #   map_reduce.counts
      #
      # @return [ Hash ] The counts.
      #
      # @since 3.0.0
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
      #
      # @since 3.0.0
      def each
        if block_given?
          documents.each do |doc|
            yield doc
          end
        else
          to_enum
        end
      end

      # Get the number of documents emitted by the map/reduce.
      #
      # @example Get the emitted document count.
      #   map_reduce.emitted
      #
      # @return [ Integer ] The number of emitted documents.
      #
      # @since 3.0.0
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
      #
      # @since 3.0.0
      def finalize(function)
        command[:finalize] = function
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
      def initialize(collection, criteria, map, reduce)
        @collection, @criteria = collection, criteria
        command[:mapreduce] = collection.name.to_s
        command[:map], command[:reduce] = map, reduce
        apply_criteria_options
      end

      # Get the number of documents that were input into the map/reduce.
      #
      # @example Get the count of input documents.
      #   map_reduce.input
      #
      # @return [ Integer ] The number of input documents.
      #
      # @since 3.0.0
      def input
        counts["input"]
      end

      # Sets the map/reduce to use jsMode.
      #
      # @example Set the map/reduce to jsMode.
      #   map_reduce.js_mode
      #
      # @return [ MapReduce ] The map/reduce.
      #
      # @since 3.0.0
      def js_mode
        command[:jsMode] = true
        self
      end

      # Specifies where the map/reduce output is to be stored.
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
      # @param [ Hash ] location The place to store the results.
      #
      # @return [ MapReduce ] The map/reduce object.
      #
      # @since 3.0.0
      def out(location)
        normalized = location.dup
        normalized.update_values do |value|
          value.is_a?(::Symbol) ? value.to_s : value
        end
        command[:out] = normalized
        self
      end

      # Get the number of documents output by the map/reduce.
      #
      # @example Get the output document count.
      #   map_reduce.output
      #
      # @return [ Integer ] The number of output documents.
      #
      # @since 3.0.0
      def output
        counts["output"]
      end

      # Get the raw output from the map/reduce operation.
      #
      # @example Get the raw output.
      #   map_reduce.raw
      #
      # @return [ Hash ] The raw output.
      #
      # @since 3.0.0
      def raw
        results
      end

      # Execute the map/reduce, returning the raw output.
      # Useful when you don't care about map/reduce's ouptut.
      #
      # @example Run the map reduce
      #   map_reduce.execute
      #
      # @return [ Hash ] The raw output
      #
      # @since 3.1.0
      alias :execute :raw

      # Get the number of documents reduced by the map/reduce.
      #
      # @example Get the reduced document count.
      #   map_reduce.reduced
      #
      # @return [ Integer ] The number of reduced documents.
      #
      # @since 3.0.0
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
      #
      # @since 3.0.0
      def scope(object)
        command[:scope] = object
        self
      end

      # Get the execution time of the map/reduce.
      #
      # @example Get the execution time.
      #   map_reduce.time
      #
      # @return [ Float ] The time in milliseconds.
      #
      # @since 3.0.0
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
      #
      # @since 3.1.0
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

      private

      # Apply criteria specific options - query, sort, limit.
      #
      # @api private
      #
      # @example Apply the criteria options
      #   map_reduce.apply_criteria_options
      #
      # @return [ nil ] Nothing.
      #
      # @since 3.0.0
      def apply_criteria_options
        command[:query] = criteria.selector
        if sort = criteria.options[:sort]
          command[:sort] = sort
        end
        if limit = criteria.options[:limit]
          command[:limit] = limit
        end
      end

      # Get the result documents from the map/reduce. If the output was inline
      # then we grab them from the results key. If the output was a temp
      # collection then we need to execute a find on that collection.
      #
      # @api private
      #
      # @example Get the documents.
      #   map_reduce.documents
      #
      # @return [ Array, Cursor ] The documents.
      #
      # @since 3.0.0
      def documents
        return results["results"] if results.has_key?("results")
        view = client[output_collection].find
        view.no_cursor_timeout if criteria.options[:timeout] == false
        view
      end

      # Get the collection that the map/reduce results were stored in.
      #
      # @api private
      #
      # @example Get the output collection.
      #   map_reduce.output_collection
      #
      # @return [ Symbol, String ] The output collection.
      #
      # @since 3.0.0
      def output_collection
        command[:out].values.first
      end

      # Execute the map/reduce command and get the results.
      #
      # @api private
      #
      # @example Get the results.
      #   map_reduce.results
      #
      # @return [ Hash ] The results of the command.
      #
      # @since 3.0.0
      def results
        raise Errors::NoMapReduceOutput.new(command) unless command[:out]
        @results ||= __client__.command(command).first
      end

      # Get the client with the proper consistency.
      #
      # @api private
      #
      # @note We can use eventual if the output is set to inline.
      #
      # @example Get the client.
      #   map_reduce.__client__
      #
      # @return [ Mongo::Client ] The client with consistency set.
      #
      # @since 3.0.15
      def __client__
        if command[:out][:inline] != 1
          # @todo: close
          client.with(read: { mode: :primary })
        else
          client
        end
      end
    end
  end
end
