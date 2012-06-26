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

      # @attribute [r] criteria The criteria for the context.
      # @attribute [r] klass The klass for the criteria.
      # @attribute [r] query The Moped query.
      attr_reader :criteria, :klass, :query

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
        count == 0
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
        klass.collection.find(criteria.and(_id: document.id).selector).count
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
          reset_length
          selecting do
            documents_for_iteration.each do |doc|
              yield_and_increment(doc, &block)
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
        count > 0
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
        if doc = FindAndModify.new(criteria, update, options).result
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
        add_type_selection
        @query = klass.collection.find(criteria.selector)
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
        MapReduce.new(criteria, map, reduce)
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
      def update(attributes = nil)
        return false unless attributes
        query.update_all(attributes.__consolidate__)
      end
      alias :update_all :update

      private

      # For models where inheritance is at play we need to add the type
      # selection.
      #
      # @example Add the type selection.
      #   context.add_type_selection
      #
      # @return [ true, false ] If type selection was added.
      #
      # @since 3.0.0
      def add_type_selection
        if klass.hereditary? && !criteria.selector.keys.include?(:_type)
          criteria.selector.merge!(_type: { "$in" => klass._types })
        end
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
          query.sort({_id: -1})
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
        if cached? && documents.any?
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
          unless docs.empty?
            if metadata.stores_foreign_key?
              child_ids = load_ids(metadata.foreign_key).flatten
              metadata.eager_load(child_ids)
            else
              parent_ids = docs.map(&:id)
              metadata.eager_load(parent_ids)
            end
          end
        end
        self.eager_loaded = true
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
        !eager_loaded && criteria.inclusions.any?
      end

      # Increment the length of the results.
      #
      # @api private
      #
      # @example Increment the length.
      #   context.increment_length
      #
      # @return [ Integer ] The new length
      #
      # @since 3.0.0
      def increment_length
        @length += 1
      end

      # Reset the length to zero. This happens once before iteration.
      #
      # @api private
      #
      # @example Reset the length.
      #   context.reset_length
      #
      # @return [ Integer ] zero.
      #
      # @since 3.0.0
      def reset_length
        @length = 0
      end

      # Loads an array of ids only for the current criteria. Used by eager
      # loading to determine the documents to load.
      #
      # @example Load the related ids.
      #   criteria.load_ids("person_id")
      #
      # @param [ String ] key The id or foriegn key string.
      #
      # @return [ Array<String, Moped::BSON::ObjectId> ] The ids to load.
      #
      # @since 3.0.0
      def load_ids(key)
        query.select(key => 1).map do |doc|
          doc[key]
        end
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
          unless criteria.options[:fields].blank?
            Threaded.selection = criteria.options[:fields]
          end
          yield
        ensure
          Threaded.selection = nil
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
          doc = Factory.from_db(klass, document)
          eager_load([ doc ]) if eager_loadable?
          doc
        end
      end

      # Yield to the document and increment the length.
      #
      # @api private
      #
      # @example Yield and increment.
      #   context.yield_and_increment(doc) do |doc|
      #     ...
      #   end
      #
      # @param [ Document ] document The document to yield to.
      #
      # @since 3.0.0
      def yield_and_increment(document, &block)
        doc = document.respond_to?(:_id) ? document : Factory.from_db(klass, document)
        yield(doc)
        increment_length
        documents.push(doc) if cacheable?
      end
    end
  end
end
