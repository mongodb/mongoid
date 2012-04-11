# encoding: utf-8
module Mongoid #:nodoc:
  module Contextual
    class MapReduce
      include Enumerable

      delegate :[], to: :results
      delegate :==, :empty?, :inspect, to: :entries

      # The database command that is being built to send to the db.
      #
      # @example Get the command.
      #   map_reduce.command
      #
      # @return [ Hash ] The db command.
      #
      # @since 3.0.0
      def command
        @command ||= {}
      end

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
      def initialize(criteria, map, reduce)
        @criteria = criteria
        command[:mapreduce] = criteria.klass.collection_name.to_s
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

      private

      # @attribute [r] criteria The criteria for the map/reduce.
      attr_reader :criteria

      # Apply criteria specific options - query, sort, limit.
      #
      # @api private
      #
      # @example Apply the criteria options
      #   map_reduce.apply_criteria_options
      #
      # @since 3.0.0
      def apply_criteria_options
        command[:query] = criteria.selector
        if sort = criteria.options[:sort]
          command[:orderby] = sort
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
        session[output_collection].find
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
        @results ||= session.command(command)
      end

      # Get the database session.
      #
      # @api private
      #
      # @example Get the session.
      #   map_reduce.session
      #
      # @return [ Session ] The Moped session.
      #
      # @since 3.0.0
      def session
        criteria.klass.mongo_session
      end
    end
  end
end
