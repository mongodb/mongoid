# encoding: utf-8
require "mongoid/contextual/atomic"
require "mongoid/contextual/aggregable"

module Mongoid #:nodoc:
  module Contextual
    class Mongo
      include Enumerable
      include Aggregable
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

      # Get the number of documents matching the query.
      #
      # @example Get the number of matching documents.
      #   context.count
      #
      # @return [ Integer ] The number of matches.
      #
      # @since 3.0.0
      def count
        query.count
      end
      alias :length :count
      alias :size :count

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
        query.count.tap do
          each do |doc|
            doc.destroy
          end
        end
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
      def each
        if block_given?
          selecting do
            if eager_loadable?
              query.map{ |doc| Factory.from_db(klass, doc) }.tap do |docs|
                eager_load(docs)
                docs.each do |doc|
                  yield doc
                end
              end
            else
              query.each do |doc|
                yield Factory.from_db(klass, doc)
              end
            end
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
        # query.explain
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
        @criteria, @klass = criteria, criteria.klass
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
        with_eager_loading(query.sort(_id: -1).first)
      end

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
      def sort(values)
        query.sort(values) and self
      end

      # Update all the matching documents atomically.
      #
      # @example Update all the matching documents.
      #   context.update(name: "Smiths")
      #
      # @param [ Hash ] attributes The new attributes for each document.
      #
      # @return [ nil, false ] False if no attributes were provided.
      #
      # @since 3.0.0
      def update(attributes = nil)
        return false unless attributes
        query.update_all({ "$set" => attributes })
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
      # @todo: Durran: Temporary.
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
          if metadata.stores_foreign_key?
            child_ids = load_ids(metadata.foreign_key).flatten
            metadata.eager_load(child_ids)
          else
            parent_ids = docs.map(&:id)
            metadata.eager_load(parent_ids)
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

      # Loads an array of ids only for the current criteria. Used by eager
      # loading to determine the documents to load.
      #
      # @example Load the related ids.
      #   criteria.load_ids("person_id")
      #
      # @param [ String ] key The id or foriegn key string.
      #
      # @return [ Array<String, BSON::ObjectId> ] The ids to load.
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
          Factory.from_db(klass, document).tap do |doc|
            eager_load([ doc ]) if eager_loadable?
          end
        end
      end
    end
  end
end
