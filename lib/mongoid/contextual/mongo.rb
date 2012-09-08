# encoding: utf-8
require "mongoid/contextual/atomic"
require "mongoid/contextual/aggregable/mongo"
require "mongoid/contextual/command"
require "mongoid/contextual/find_and_modify"
require "mongoid/contextual/map_reduce"

module Mongoid
  module Contextual
    class Mongo
      include Enumerable
      include Aggregable::Mongo
      include Atomic

      # @attribute [r] collection The collection to query against.
      # @attribute [r] criteria The criteria for the context.
      # @attribute [r] klass The klass for the criteria.
      # @attribute [r] query The Moped query.
      attr_reader :collection, :criteria, :klass, :query

      # @attribute [rw] eager_loaded Has the context been eager loaded?
      attr_accessor :eager_loaded

      # Is the enumerable of matching documents empty?
      #
      # @example Is the context empty?
      #   context.blank?
      #
      # @return [ true, false ] If the context is empty.
      #
      # @since 3.0.0
      def blank?
        !exists?
      end
      alias :empty? :blank?

      # Is the context cached?
      #
      # @example Is the context cached?
      #   context.cached?
      #
      # @return [ true, false ] If the context is cached.
      #
      # @since 3.0.0
      def cached?
        !!@cache
      end

      # Get the number of documents matching the query.
      #
      # @example Get the number of matching documents.
      #   context.count
      #
      # @example Get the count of documents matching the provided.
      #   context.count(document)
      #
      # @example Get the count for where the provided block is true.
      #   context.count do |doc|
      #     doc.likes > 1
      #   end
      #
      # @param [ Document ] document A document ot match.
      #
      # @return [ Integer ] The number of matches.
      #
      # @since 3.0.0
      def count(document = nil, &block)
        return super(&block) if block_given?
        return query.count unless document
        collection.find(criteria.and(_id: document.id).selector).count
      end

      # Delete all documents in the database that match the selector.
      #
      # @example Delete all the documents.
      #   context.delete
      #
      # @return [ nil ] Nil.
      #
      # @since 3.0.0
      def delete
        query.count.tap do
          query.remove_all
        end
      end
      alias :delete_all :delete

      # Destroy all documents in the database that match the selector.
      #
      # @example Destroy all the documents.
      #   context.destroy
      #
      # @return [ nil ] Nil.
      #
      # @since 3.0.0
      def destroy
        destroyed = query.count
        each do |doc|
          doc.destroy
        end
        destroyed
      end
      alias :destroy_all :destroy

      # Get the distinct values in the db for the provided field.
      #
      # @example Get the distinct values.
      #   context.distinct(:name)
      #
      # @param [ String, Symbol ] field The name of the field.
      #
      # @return [ Array<Object> ] The distinct values for the field.
      #
      # @since 3.0.0
      def distinct(field)
        query.distinct(field)
      end

      # Iterate over the context. If provided a block, yield to a Mongoid
      # document for each, otherwise return an enum.
      #
      # @example Iterate over the context.
      #   context.each do |doc|
      #     puts doc.name
      #   end
      #
      # @return [ Enumerator ] The enumerator.
      #
      # @since 3.0.0
      def each(&block)
        if block_given?
          selecting do
            documents_for_iteration.each do |doc|
              yield_document(doc, &block)
            end
            @cache_loaded = true
            eager_loadable? ? docs : self
          end
        else
          to_enum
        end
      end

      # Do any documents exist for the context.
      #
      # @example Do any documents exist for the context.
      #   context.exists?
      #
      # @return [ true, false ] If the count is more than zero.
      #
      # @since 3.0.0
      def exists?
        # Don't use count here since Mongo does not use counted b-tree indexes
        !query.dup.select(_id: 1).limit(1).entries.first.nil?
      end

      # Run an explain on the criteria.
      #
      # @example Explain the criteria.
      #   Band.where(name: "Depeche Mode").explain
      #
      # @return [ Hash ] The explain result.
      #
      # @since 3.0.0
      def explain
        query.explain
      end

      # Execute the find and modify command, used for MongoDB's
      # $findAndModify.
      #
      # @example Execute the command.
      #   context.find_and_modify({ "$inc" => { likes: 1 }}, new: true)
      #
      # @param [ Hash ] update The updates.
      # @param [ Hash ] options The command options.
      #
      # @option options [ true, false ] :new Return the updated document.
      # @option options [ true, false ] :remove Delete the first document.
      # @option options [ true, false ] :upsert Create the document if it doesn't exist.
      #
      # @return [ Document ] The result of the command.
      #
      # @since 3.0.0
      def find_and_modify(update, options = {})
        if doc = FindAndModify.new(collection, criteria, update, options).result
          Factory.from_db(klass, doc)
        end
      end

      # Get the first document in the database for the criteria's selector.
      #
      # @example Get the first document.
      #   context.first
      #
      # @return [ Document ] The first document.
      #
      # @since 3.0.0
      def first
        apply_id_sorting
        with_eager_loading(query.first)
      end
      alias :one :first

      # Create the new Mongo context. This delegates operations to the
      # underlying driver - in Mongoid's case Moped.
      #
      # @example Create the new context.
      #   Mongo.new(criteria)
      #
      # @param [ Criteria ] criteria The criteria.
      #
      # @since 3.0.0
      def initialize(criteria)
        @criteria, @klass, @cache = criteria, criteria.klass, criteria.options[:cache]
        @collection = klass.collection
        criteria.send(:merge_type_selection)
        @query = collection.find(criteria.selector)
        apply_options
      end

      # Get the last document in the database for the criteria's selector.
      #
      # @example Get the last document.
      #   context.last
      #
      # @return [ Document ] The last document.
      #
      # @since 3.0.0
      def last
        apply_inverse_sorting
        with_eager_loading(query.first)
      end

      # Get's the number of documents matching the query selector.
      #
      # @example Get the length.
      #   context.length
      #
      # @return [ Integer ] The number of documents.
      #
      # @since 3.0.0
      def length
        @length ||= query.count
      end
      alias :size :length

      # Limits the number of documents that are returned from the database.
      #
      # @example Limit the documents.
      #   context.limit(20)
      #
      # @param [ Integer ] value The number of documents to return.
      #
      # @return [ Mongo ] The context.
      #
      # @since 3.0.0
      def limit(value)
        query.limit(value) and self
      end

      # Initiate a map/reduce operation from the context.
      #
      # @example Initiate a map/reduce.
      #   context.map_reduce(map, reduce)
      #
      # @param [ String ] map The map js function.
      # @param [ String ] reduce The reduce js function.
      #
      # @return [ MapReduce ] The map/reduce lazy wrapper.
      #
      # @since 3.0.0
      def map_reduce(map, reduce)
        MapReduce.new(collection, criteria, map, reduce)
      end

      # Skips the provided number of documents.
      #
      # @example Skip the documents.
      #   context.skip(20)
      #
      # @param [ Integer ] value The number of documents to skip.
      #
      # @return [ Mongo ] The context.
      #
      # @since 3.0.0
      def skip(value)
        query.skip(value) and self
      end

      # Sorts the documents by the provided spec.
      #
      # @example Sort the documents.
      #   context.sort(name: -1, title: 1)
      #
      # @param [ Hash ] values The sorting values as field/direction(1/-1)
      #   pairs.
      #
      # @return [ Mongo ] The context.
      #
      # @since 3.0.0
      def sort(values = nil, &block)
        if block_given?
          super(&block)
        else
          query.sort(values) and self
        end
      end

      # Update the first matching document atomically.
      #
      # @example Update the first matching document.
      #   context.update({ "$set" => { name: "Smiths" }})
      #
      # @param [ Hash ] attributes The new attributes for each document.
      #
      # @return [ nil, false ] False if no attributes were provided.
      #
      # @since 3.0.0
      def update(attributes = nil)
        update_documents(attributes)
      end

      # Update all the matching documents atomically.
      #
      # @example Update all the matching documents.
      #   context.update({ "$set" => { name: "Smiths" }})
      #
      # @param [ Hash ] attributes The new attributes for each document.
      #
      # @return [ nil, false ] False if no attributes were provided.
      #
      # @since 3.0.0
      def update_all(attributes = nil)
        update_documents(attributes, :update_all)
      end

      private

      # Update the documents for the provided method.
      #
      # @api private
      #
      # @example Update the documents.
      #   context.update_documents(attrs)
      #
      # @param [ Hash ] attributes The updates.
      # @param [ Symbol ] method The method to use.
      #
      # @return [ true, false ] If the update succeeded.
      #
      # @since 3.0.4
      def update_documents(attributes, method = :update)
        return false unless attributes
        query.send(method, attributes.__consolidate__)
      end

      # Apply the field limitations.
      #
      # @api private
      #
      # @example Apply the field limitations.
      #   context.apply_fields
      #
      # @since 3.0.0
      def apply_fields
        if spec = criteria.options[:fields]
          query.select(spec)
        end
      end

      # Apply the skip option.
      #
      # @api private
      #
      # @example Apply the skip option.
      #   context.apply_skip
      #
      # @since 3.0.0
      def apply_skip
        if spec = criteria.options[:skip]
          query.skip(spec)
        end
      end

      # Apply the limit option.
      #
      # @api private
      #
      # @example Apply the limit option.
      #   context.apply_limit
      #
      # @since 3.0.0
      def apply_limit
        if spec = criteria.options[:limit]
          query.limit(spec)
        end
      end

      # Map the sort symbols to the correct MongoDB values.
      #
      # @example Apply the sorting params.
      #   context.apply_sorting
      #
      # @since 3.0.0
      def apply_sorting
        if spec = criteria.options[:sort]
          query.sort(spec)
        end
      end

      # Apply the hint option
      #
      # @example Apply the hint params.
      #   context.apply_hint
      #
      # @since 3.0.0
      def apply_hint
        if spec = criteria.options[:hint]
          query.hint(spec)
        end
      end

      # Apply an ascending id sort for use with #first queries, only if no
      # other sorting is provided.
      #
      # @api private
      #
      # @example Apply the id sorting params.
      #   context.apply_dd_sorting
      #
      # @since 3.0.0
      def apply_id_sorting
        unless criteria.options.has_key?(:sort)
          query.sort(_id: 1)
        end
      end

      # Map the inverse sort symbols to the correct MongoDB values.
      #
      # @example Apply the inverse sorting params.
      #   context.apply_inverse_sorting
      #
      # @since 3.0.0
      def apply_inverse_sorting
        if spec = criteria.options[:sort]
          query.sort(Hash[spec.map{|k, v| [k, -1*v]}])
        else
          query.sort(_id: -1)
        end
      end

      # Is the cache able to be added to?
      #
      # @api private
      #
      # @example Is the context cacheable?
      #   context.cacheable?
      #
      # @return [ true, false ] If caching, and the cache isn't loaded.
      #
      # @since 3.0.0
      def cacheable?
        cached? && !cache_loaded?
      end

      # Is the cache fully loaded? Will be true if caching after one full
      # iteration.
      #
      # @api private
      #
      # @example Is the cache loaded?
      #   context.cache_loaded?
      #
      # @return [ true, false ] If the cache is loaded.
      #
      # @since 3.0.0
      def cache_loaded?
        !!@cache_loaded
      end

      # Get the documents for cached queries.
      #
      # @api private
      #
      # @example Get the cached documents.
      #   context.documents
      #
      # @return [ Array<Document> ] The documents.
      #
      # @since 3.0.0
      def documents
        @documents ||= []
      end

      # Get the documents the context should iterate. This follows 3 rules:
      #
      # 1. If the query is cached, and we already have documents loaded, use
      #   them.
      # 2. If we are eager loading, then eager load the documents and use
      #   those.
      # 3. Use the query.
      #
      # @api private
      #
      # @example Get the documents for iteration.
      #   context.documents_for_iteration
      #
      # @return [ Array<Document>, Moped::Query ] The docs to iterate.
      #
      # @since 3.0.0
      def documents_for_iteration
        if cached? && !documents.empty?
          documents
        elsif eager_loadable?
          docs = query.map{ |doc| Factory.from_db(klass, doc) }
          eager_load(docs)
          docs
        else
          query
        end
      end

      # Eager load the inclusions for the provided documents.
      #
      # @example Eager load the inclusions.
      #   context.eager_load(docs)
      #
      # @param [ Array<Document> ] docs The docs returning from the db.
      #
      # @return [ true ] Always true.
      #
      # @since 3.0.0
      def eager_load(docs)
        criteria.inclusions.reject! do |metadata|
          metadata.eager_load(eager_loaded_ids(docs, metadata)) if !docs.empty?
        end
        self.eager_loaded = true
      end

      # Get the ids that to be used to eager load documents.
      #
      # @api private
      #
      # @example Get the ids.
      #   context.eager_load(docs, metadata)
      #
      # @param [ Array<Document> ] docs The pre-loaded documents.
      # @param [ Metadata ] metadata The relation metadata.
      #
      # @return [ Array<Object> ] The ids.
      #
      # @since 3.0.0
      def eager_loaded_ids(docs, metadata)
        if metadata.stores_foreign_key?
          docs.flat_map{ |doc| doc.send(metadata.foreign_key) }
        else
          docs.map(&:id)
        end
      end

      # Is this context able to be eager loaded?
      #
      # @example Is the context eager loadable?
      #   context.eager_loadable?
      #
      # @return [ true, false ] If the context is able to be eager loaded.
      #
      # @since 3.0.0
      def eager_loadable?
        !eager_loaded && !criteria.inclusions.empty?
      end

      # Apply all the optional criterion.
      #
      # @example Apply the options.
      #   context.apply_options
      #
      # @since 3.0.0
      def apply_options
        apply_fields
        apply_limit
        apply_skip
        apply_sorting
        apply_hint
      end

      # If we are limiting results, we need to set the field limitations on a
      # thread local to avoid overriding the default values.
      #
      # @example Execute with selection.
      #   context.selecting do
      #     collection.find
      #   end
      #
      # @return [ Object ] The yielded value.
      #
      # @since 2.4.4
      def selecting
        begin
          fields = criteria.options[:fields]
          Threaded.set_selection(criteria.object_id, fields) unless fields.blank?
          yield
        ensure
          Threaded.set_selection(criteria.object_id, nil)
        end
      end

      # If the provided document exists, eager load it's dependencies or return
      # nil.
      #
      # @example Eager load if the document is not nil.
      #   context.with_eager_loading(document)
      #
      # @param [ Hash ] document The document from the database.
      #
      # @return [ Document, nil ] The instantiated model document.
      #
      # @since 3.0.0
      def with_eager_loading(document)
        selecting do
          return nil unless document
          doc = Factory.from_db(klass, document, criteria.object_id)
          eager_load([ doc ]) if eager_loadable?
          doc
        end
      end

      # Yield to the document.
      #
      # @api private
      #
      # @example Yield the document.
      #   context.yield_document(doc) do |doc|
      #     ...
      #   end
      #
      # @param [ Document ] document The document to yield to.
      #
      # @since 3.0.0
      def yield_document(document, &block)
        doc = document.respond_to?(:_id) ?
          document : Factory.from_db(klass, document, criteria.object_id)
        yield(doc)
        documents.push(doc) if cacheable?
      end
    end
  end
end
