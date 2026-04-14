# frozen_string_literal: true

module Mongoid
  # Encapsulates behavior around managing search indexes. This feature
  # is only supported when connected to an Atlas cluster.
  module SearchIndexable
    extend ActiveSupport::Concern

    # Represents the status of the indexes returned by a search_indexes
    # call.
    #
    # @api private
    class Status
      # @return [ Array<Hash> ] the raw index documents
      attr_reader :indexes

      # Create a new Status object.
      #
      # @param [ Array<Hash> ] indexes the raw index documents
      def initialize(indexes)
        @indexes = indexes
      end

      # Returns the subset of indexes that have status == 'READY'
      #
      # @return [ Array<Hash> ] index documents for "ready" indices
      def ready
        indexes.select { |i| i['status'] == 'READY' }
      end

      # Returns the subset of indexes that have status == 'PENDING'
      #
      # @return [ Array<Hash> ] index documents for "pending" indices
      def pending
        indexes.select { |i| i['status'] == 'PENDING' }
      end

      # Returns the subset of indexes that are marked 'queryable'
      #
      # @return [ Array<Hash> ] index documents for 'queryable' indices
      def queryable
        indexes.select { |i| i['queryable'] }
      end

      # Returns true if all the given indexes are 'ready' and 'queryable'.
      #
      # @return [ true | false ] ready status of all indexes
      def ready?
        indexes.all? { |i| i['status'] == 'READY' && i['queryable'] }
      end
    end

    included do
      cattr_accessor :search_index_specs
      self.search_index_specs = []
    end

    # Performs a vector search for documents similar to this one, using
    # this document's stored embedding as the query vector. The document
    # itself is excluded from the results.
    #
    # @example Find articles similar to this one.
    #   article.vector_search(limit: 5, filter: { status: 'published' })
    #
    # @param [ String | Symbol | nil ] index The name of the vector search
    #   index to use (optional if only one is declared on the model).
    # @param [ String | Symbol | nil ] path The field containing the stored
    #   vector (optional if unambiguous from the index definition).
    # @param [ Integer ] limit The maximum number of results (default: 10).
    # @param [ Integer | nil ] num_candidates The number of candidates to
    #   consider during the ANN search; defaults to limit * 10.
    # @param [ Hash | nil ] filter An optional MongoDB filter to pre-filter
    #   candidates before scoring.
    # @param [ Array ] pipeline Additional aggregation stages to append after
    #   the vector search and score projection.
    #
    # @return [ Array<Mongoid::Document> ] matching documents, each with
    #   a populated +vector_search_score+ attribute.
    def vector_search(index: nil, path: nil, limit: 10, num_candidates: nil, filter: nil, pipeline: [])
      _index, resolved_path = self.class.send(:resolve_vector_index, index, path)
      query_vector = public_send(resolved_path)

      if query_vector.nil?
        raise ArgumentError,
              "#{resolved_path} is nil on this document; cannot perform vector search"
      end

      self_filter = { '_id' => { '$ne' => _id } }
      combined_filter = filter ? { '$and' => [ self_filter, filter ] } : self_filter

      self.class.vector_search(
        query_vector,
        index: index,
        path: path,
        limit: limit,
        num_candidates: num_candidates,
        filter: combined_filter,
        pipeline: pipeline
      )
    end

    # Performs an Atlas Vector Search query for documents with text similar
    # to this document's stored text field, using auto-embedding. The current
    # document is excluded from the results.
    #
    # @example Find articles with similar descriptions.
    #   article.auto_embed_search(limit: 5, filter: { status: 'published' })
    #
    # @param [ String | Symbol | nil ] index The name of the auto-embed index
    #   to use (optional when only one is declared on the model).
    # @param [ String | Symbol | nil ] path The indexed text field path
    #   (optional if unambiguous from the index definition).
    # @param [ Integer ] limit Maximum number of results (default: 10).
    # @param [ Integer | nil ] num_candidates Candidates for ANN search;
    #   defaults to limit * 10. Ignored when exact: true.
    # @param [ Hash | nil ] filter Optional MongoDB filter for pre-filtering.
    # @param [ true | false ] exact Use exact nearest-neighbor search (default: false).
    # @param [ String | nil ] model Query-time embedding model override.
    # @param [ Array ] pipeline Additional aggregation stages to append.
    #
    # @return [ Array<Mongoid::Document> ] matching documents, each with
    #   a populated +vector_search_score+ attribute.
    def auto_embed_search(index: nil, path: nil, limit: 10, num_candidates: nil, filter: nil, exact: false, model: nil, pipeline: []) # rubocop:disable Metrics/ParameterLists
      _index, resolved_path = self.class.send(:resolve_auto_embed_index, index, path)
      text = public_send(resolved_path)

      if text.nil?
        raise ArgumentError,
              "#{resolved_path} is nil on this document; cannot perform auto-embed search"
      end

      self_filter = { '_id' => { '$ne' => _id } }
      combined_filter = filter ? { '$and' => [ self_filter, filter ] } : self_filter

      self.class.auto_embed_search(
        text,
        index: index,
        path: path,
        limit: limit,
        num_candidates: num_candidates,
        filter: combined_filter,
        exact: exact,
        model: model,
        pipeline: pipeline
      )
    end

    # Implementations for the feature's class-level methods.
    module ClassMethods
      # Request the creation of all registered search indices. Note
      # that the search indexes are created asynchronously, and may take
      # several minutes to be fully available.
      #
      # @return [ Array<String> ] The names of the search indexes.
      def create_search_indexes
        return if search_index_specs.empty?

        collection.search_indexes.create_many(search_index_specs)
      end

      # Waits for the named search indexes to be created.
      #
      # @param [ Array<String> ] names the list of index names to wait for
      # @param [ Integer ] interval the number of seconds to wait before
      #   polling again (only used when a progress callback is given).
      #
      # @yield [ SearchIndexable::Status ] the status object
      def wait_for_search_indexes(names, interval: 5)
        loop do
          status = Status.new(get_indexes(names))
          yield status if block_given?
          break if status.ready?

          sleep interval
        end
      end

      # A convenience method for querying the search indexes available on the
      # current model's collection.
      #
      # @param [ Hash ] options the options to pass through to the search
      #   index query.
      #
      # @option options [ String ] :id The id of the specific index to query (optional)
      # @option options [ String ] :name The name of the specific index to query (optional)
      # @option options [ Hash ] :aggregate The options hash to pass to the
      #    aggregate command (optional)
      def search_indexes(options = {})
        collection.search_indexes(options)
      end

      # Removes the search index specified by the given name or id. Either
      # name OR id must be given, but not both.
      #
      # @param [ String | nil ] name the name of the index to remove
      # @param [ String | nil ] id the id of the index to remove
      def remove_search_index(name: nil, id: nil)
        logger.info(
          "MONGOID: Removing search index '#{name || id}' " \
          "on collection '#{collection.name}'."
        )

        collection.search_indexes.drop_one(name: name, id: id)
      end

      # Request the removal of all registered search indexes. Note
      # that the search indexes are removed asynchronously, and may take
      # several minutes to be fully deleted.
      #
      # @note It would be nice if this could remove ONLY the search indexes
      # that have been declared on the model, but because the model may not
      # name the index, we can't guarantee that we'll know the name or id of
      # the corresponding indexes. It is not unreasonable to assume, though,
      # that the intention is for the model to declare, one-to-one, all
      # desired search indexes, so removing all search indexes ought to suffice.
      # If a specific index or set of indexes needs to be removed instead,
      # consider using search_indexes.each with remove_search_index.
      def remove_search_indexes
        search_indexes.each do |spec|
          remove_search_index id: spec['id']
        end
      end

      # Adds an index definition for the provided single or compound keys.
      #
      # @example Create a basic index.
      #   class Person
      #     include Mongoid::Document
      #     field :name, type: String
      #     search_index({ ... })
      #     search_index :name_of_index, { ... }
      #   end
      #
      # @param [ Symbol | String | Hash ] name_or_defn Either the name of the index to
      #    define, or the index definition.
      # @param [ Hash ] defn The search index definition.
      def search_index(name_or_defn, defn = nil)
        name = name_or_defn
        name, defn = nil, name if name.is_a?(Hash)

        spec = { definition: defn }.tap { |s| s[:name] = name.to_s if name }
        search_index_specs.push(spec)
      end

      # Adds a vector search index definition. Also defines a read-only
      # +vector_search_score+ field on the model the first time it is called,
      # which is populated on documents returned by +vector_search+.
      #
      # @example Create a vector search index.
      #   class Person
      #     include Mongoid::Document
      #     vector_search_index({ fields: [...] })
      #     vector_search_index :my_vector_index, { fields: [...] }
      #   end
      #
      # @param [ Symbol | String | Hash ] name_or_defn Either the name of the index to
      #    define, or the index definition.
      # @param [ Hash ] defn The vector search index definition.
      def vector_search_index(name_or_defn, defn = nil)
        name = name_or_defn
        name, defn = nil, name if name.is_a?(Hash)

        spec = { type: 'vectorSearch', definition: defn }.tap { |s| s[:name] = name.to_s if name }
        search_index_specs.push(spec)

        return if fields.key?('vector_search_score')

        field :vector_search_score, type: Float
        attr_readonly :vector_search_score
      end

      # Performs an Atlas Vector Search query and returns matching documents.
      # Each returned document has a +vector_search_score+ attribute populated
      # with its relevance score.
      #
      # The vector field (given by +path:+) is excluded from the returned
      # documents by default, as vectors are large and rarely useful after
      # retrieval.
      #
      # @example Search by an explicit query vector.
      #   Article.vector_search(embedding, limit: 5, filter: { status: 'published' })
      #
      # @param [ Array<Numeric> ] vector The query vector.
      # @param [ String | Symbol | nil ] index The name of the vector search
      #   index to use (optional if only one is declared on the model).
      # @param [ String | Symbol | nil ] path The field containing the stored
      #   vector (optional if unambiguous from the index definition).
      # @param [ Integer ] limit The maximum number of results (default: 10).
      # @param [ Integer | nil ] num_candidates The number of candidates to
      #   consider during the ANN search; defaults to limit * 10.
      # @param [ Hash | nil ] filter An optional MongoDB filter to pre-filter
      #   candidates before scoring.
      # @param [ Array ] pipeline Additional aggregation stages to append after
      #   the vector search and score projection.
      #
      # @return [ Array<Mongoid::Document> ] matching documents, each with
      #   a populated +vector_search_score+ attribute.
      def vector_search(vector, index: nil, path: nil, limit: 10, num_candidates: nil, filter: nil, pipeline: []) # rubocop:disable Metrics/ParameterLists
        resolved_index, resolved_path = resolve_vector_index(index, path)
        num_candidates ||= limit * 10

        vs_options = {
          'index' => resolved_index,
          'path' => resolved_path,
          'queryVector' => vector,
          'numCandidates' => num_candidates,
          'limit' => limit
        }
        vs_options['filter'] = filter if filter

        agg_pipeline = [
          { '$vectorSearch' => vs_options },
          { '$addFields'    => { 'vector_search_score' => { '$meta' => 'vectorSearchScore' } } },
          { '$project'      => { resolved_path => 0 } }
        ]
        agg_pipeline.concat(Array(pipeline))

        collection.aggregate(agg_pipeline).map { |doc| instantiate(doc) }
      end

      # Performs an Atlas Vector Search query using auto-embedding. Atlas
      # generates the query vector from the supplied text at query time; no
      # pre-computed embedding is required.
      #
      # Each returned document has a +vector_search_score+ attribute populated
      # with its relevance score.
      #
      # @example Search by text.
      #   Article.auto_embed_search('machine learning', limit: 5)
      #
      # @example Exact nearest-neighbor search (no numCandidates).
      #   Article.auto_embed_search('deep learning', exact: true, limit: 5)
      #
      # @param [ String ] text The query text.
      # @param [ String | Symbol | nil ] index The name of the auto-embed index
      #   to use (optional when only one is declared on the model).
      # @param [ String | Symbol | nil ] path The indexed text field path
      #   (optional if unambiguous from the index definition).
      # @param [ Integer ] limit Maximum number of results (default: 10).
      # @param [ Integer | nil ] num_candidates Candidates for ANN search;
      #   defaults to limit * 10. Ignored when exact: true.
      # @param [ Hash | nil ] filter Optional MongoDB filter for pre-filtering.
      # @param [ true | false ] exact Use exact nearest-neighbor (ENN) search
      #   instead of ANN (default: false). When true, numCandidates is omitted.
      # @param [ String | nil ] model Query-time embedding model override.
      # @param [ Array ] pipeline Additional aggregation stages appended after
      #   the vector search and score projection.
      #
      # @return [ Array<Mongoid::Document> ] matching documents, each with
      #   a populated +vector_search_score+ attribute.
      def auto_embed_search(text, index: nil, path: nil, limit: 10, num_candidates: nil, filter: nil, exact: false, model: nil, pipeline: []) # rubocop:disable Metrics/ParameterLists
        resolved_index, resolved_path = resolve_auto_embed_index(index, path)

        vs_options = {
          'index' => resolved_index,
          'path' => resolved_path,
          'query' => { 'text' => text },
          'limit' => limit
        }
        vs_options['numCandidates'] = num_candidates || (limit * 10) unless exact
        vs_options['exact'] = true if exact
        vs_options['filter'] = filter if filter
        vs_options['model'] = model if model

        agg_pipeline = [
          { '$vectorSearch' => vs_options },
          { '$addFields'    => { 'vector_search_score' => { '$meta' => 'vectorSearchScore' } } }
        ]
        agg_pipeline.concat(Array(pipeline))

        collection.aggregate(agg_pipeline).map { |doc| instantiate(doc) }
      end

      private

      # Retrieves the index records for the indexes with the given names.
      #
      # @param [ Array<String> ] names the index names to query
      #
      # @return [ Array<Hash> ] the raw index documents
      def get_indexes(names)
        collection.search_indexes.select { |i| names.include?(i['name']) }
      end

      # Resolves the index name and vector path from the declared specs,
      # applying inference when either is omitted.
      #
      # @param [ String | Symbol | nil ] index The requested index name.
      # @param [ String | Symbol | nil ] path The requested field path.
      #
      # @return [ Array<String> ] the resolved [ index_name, field_path ] pair.
      def resolve_vector_index(index, path)
        vector_specs = search_index_specs.select { |s| s[:type] == 'vectorSearch' }

        raise ArgumentError, "No vector search indexes declared on #{name}" if vector_specs.empty?

        spec = if index
                 found = vector_specs.find { |s| s[:name] == index.to_s }
                 raise ArgumentError, "No vector search index '#{index}' declared on #{name}" unless found

                 found
               elsif vector_specs.size == 1
                 vector_specs.first
               else
                 raise ArgumentError,
                       "#{name} has multiple vector search indexes; specify index: to select one"
               end

        resolved_index = spec[:name] || 'default'
        resolved_path  = path ? path.to_s : infer_vector_path(spec)

        [ resolved_index, resolved_path ]
      end

      # Infers the vector field path from the index definition by locating
      # the first field declared with type 'vector'.
      #
      # @param [ Hash ] spec The vector search index spec.
      #
      # @return [ String ] the field path.
      def infer_vector_path(spec)
        field_list = spec.dig(:definition, :fields) || spec.dig(:definition, 'fields') || []
        vector_field = field_list.find { |f| (f[:type] || f['type']) == 'vector' }

        unless vector_field
          raise ArgumentError,
                "Cannot infer vector path on #{name}: no 'vector' type field in index definition; specify path:"
        end

        (vector_field[:path] || vector_field['path']).to_s
      end

      # Resolves the index name and text field path for an auto-embedding
      # query, applying inference when either is omitted.
      #
      # @param [ String | Symbol | nil ] index The requested index name.
      # @param [ String | Symbol | nil ] path The requested field path.
      #
      # @return [ Array<String> ] the resolved [ index_name, field_path ] pair.
      def resolve_auto_embed_index(index, path)
        auto_embed_specs = search_index_specs.select do |s|
          s[:type] == 'vectorSearch' &&
            (s.dig(:definition, :fields) || s.dig(:definition, 'fields') || [])
              .any? { |f| (f[:type] || f['type']) == 'autoEmbed' }
        end

        raise ArgumentError, "No auto-embed indexes declared on #{name}" if auto_embed_specs.empty?

        # Extracted to keep cyclomatic complexity within RuboCop's threshold.
        spec = select_auto_embed_spec(auto_embed_specs, index)
        resolved_index = spec[:name] || 'default'
        resolved_path  = path ? path.to_s : infer_auto_embed_path(spec)

        [ resolved_index, resolved_path ]
      end

      # Picks one spec from the list of auto-embed specs, guided by +index+.
      #
      # @param [ Array<Hash> ] specs The candidate auto-embed specs.
      # @param [ String | Symbol | nil ] index The requested index name.
      #
      # @return [ Hash ] the selected spec.
      def select_auto_embed_spec(specs, index)
        if index
          found = specs.find { |s| s[:name] == index.to_s }
          raise ArgumentError, "No auto-embed index '#{index}' declared on #{name}" unless found

          found
        elsif specs.size == 1
          specs.first
        else
          raise ArgumentError,
                "#{name} has multiple auto-embed indexes; specify index: to select one"
        end
      end

      # Infers the text field path from an index definition by locating
      # the first field declared with type 'autoEmbed'.
      #
      # @param [ Hash ] spec The vector search index spec.
      #
      # @return [ String ] the field path.
      def infer_auto_embed_path(spec)
        field_list = spec.dig(:definition, :fields) || spec.dig(:definition, 'fields') || []
        ae_field   = field_list.find { |f| (f[:type] || f['type']) == 'autoEmbed' }

        unless ae_field
          raise ArgumentError,
                "Cannot infer path on #{name}: no 'autoEmbed' field in index definition; specify path:"
        end

        (ae_field[:path] || ae_field['path']).to_s
      end
    end
  end
end
