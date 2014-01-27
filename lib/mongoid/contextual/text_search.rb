# encoding: utf-8
module Mongoid
  module Contextual

    # Wraps behaviour around a lazy text search command.
    #
    # @since 4.0.0
    class TextSearch
      include Enumerable
      include Command

      delegate :[], to: :results
      delegate :==, :empty?, to: :entries

      # Iterate over the results of the text search command.
      #
      # @example Iterate over the results.
      #   text_search.each do |doc|
      #     #...
      #   end
      #
      # @return [ Enumerator ] The enumerator.
      #
      # @since 4.0.0
      def each
        if block_given?
          documents.each do |doc|
            yield doc
          end
        else
          to_enum
        end
      end

      # Instantiate a new text search lazy proxy.
      #
      # @example Instantiate the text search.
      #   TextSearch.new(collection, criteria, "test")
      #
      # @param [ Moped::Collection ] collection The collection to execute on.
      # @param [ Criteria ] criteria The criteria to filter results.
      # @param [ String ] search_string The search string.
      #
      # @since 4.0.0
      def initialize(collection, criteria, search_string)
        @collection, @criteria = collection, criteria
        command[:text] = collection.name.to_s
        command[:search] = search_string
        apply_criteria_options
      end

      # Inspect the text search object.
      #
      # @example Inspect the text search.
      #   text_search.inspect
      #
      # @return [ String ] The inspection.
      #
      # @since 4.0.0
      def inspect
%Q{#<Mongoid::Contextual::TextSearch
  selector:   #{criteria.selector.inspect}
  class:      #{criteria.klass}
  search:     #{command[:search]}
  filter:     #{command[:filter] || "N/A"}
  project:    #{command[:project] || "N/A"}
  limit:      #{command[:limit] || "N/A"}
  language:   #{command[:language] || "default"}>
}
      end

      # Execute the text search command, and return the raw results (in hash
      # form).
      #
      # @example Execute the command.
      #   text_search.execute
      #
      # @return [ Hash ] The raw results.
      #
      # @since 4.0.0
      def execute
        results
      end

      # Set the language of the text search.
      #
      # @example Set the text search language.
      #   text_search.language("deutsch")
      #
      # @param [ String ] value The name of the language.
      #
      # @return [ TextSearch ] The modified text search.
      #
      # @since 4.0.0
      def language(value)
        command[:language] = value
        self
      end

      # Limits the fields returned by the text search for each document. By
      # default, _id is always included.
      #
      # @example Limit the returned fields.
      #   text_search.project(name: 1, title: 1)
      #
      # @param [ Hash ] value The fields to project.
      #
      # @return [ TextSearch ] The modified text search.
      #
      # @since 4.0.0
      def project(value)
        command[:project] = value
        self
      end

      # Get the raw statistics returned from the text search.
      #
      # @example Get the stats.
      #   text_search.stats
      #
      # @return [ Hash ] The raw statistics.
      #
      # @since 4.0.0
      def stats
        results["stats"]
      end

      private

      # Apply the options from the criteria to the text search command.
      #
      # @api private
      #
      # @example Apply the criteria options, filter and limit only.
      #   text_search.apply_criteria_options
      #
      # @return [ nil ] Nothing.
      #
      # @since 4.0.0
      def apply_criteria_options
        command[:filter] = criteria.selector
        if limit = criteria.options[:limit]
          command[:limit] = limit
        end
      end

      # Get the results of the text search as documents.
      #
      # @api private
      #
      # @example Get the results as documents.
      #   text_search.documents
      #
      # @return [ Array<Document> ] The documents.
      #
      # @since 4.0.0
      def documents
        results["results"].map do |attributes|
          Factory.from_db(criteria.klass, attributes["obj"], command[:project])
        end
      end

      # Get the raw results.
      #
      # @api private
      #
      # @example Get the raw results.
      #   text_search.results
      #
      # @return [ Hash ] The raw results.
      #
      # @since 4.0.0
      def results
        @results ||= session.command(command)
      end
    end
  end
end
