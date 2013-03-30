# encoding: utf-8
require "mongoid/contextual/atomic"
require "mongoid/contextual/aggregable/mongo"
require "mongoid/contextual/command"
require "mongoid/contextual/eager"
require "mongoid/contextual/find_and_modify"
require "mongoid/contextual/geo_near"
require "mongoid/contextual/map_reduce"

module Mongoid
  module Contextual
    class Mongo
      include Enumerable
      include Aggregable::Mongo
      include Atomic
      include Eager
      include Queryable

      # @attribute [r] query The Moped query.
      attr_reader :query

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
      # @param [ Document ] document A document to match or true if wanting
      #   skip and limit to be factored into the count.
      #
      # @return [ Integer ] The number of matches.
      #
      # @since 3.0.0
      def count(document = false, &block)
        return super(&block) if block_given?
        if document.is_a?(Document)
          return collection.find(criteria.and(_id: document.id).selector).count
        end
        return query.count(document) if document
        cached? ? @count ||= query.count : query.count
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
        self.count.tap do
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
        destroyed = self.count
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
        query.distinct(klass.database_field_name(field))
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
      # @note We don't use count here since Mongo does not use counted
      #   b-tree indexes, unless a count is already cached then that is
      #   used to determine the value.
      #
      # @return [ true, false ] If the count is more than zero.
      #
      # @since 3.0.0
      def exists?
        @exists ||= check_existence
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
        if cached? && cache_loaded?
          documents.first
        else
          with_sorting do
            with_eager_loading(query.first)
          end
        end
      end
      alias :one :first

      # Execute a $geoNear command against the database.
      #
      # @example Find documents close to 10, 10.
      #   context.geo_near([ 10, 10 ])
      #
      # @example Find with spherical distance.
      #   context.geo_near([ 10, 10 ]).spherical
      #
      # @example Find with a max distance.
      #   context.geo_near([ 10, 10 ]).max_distance(0.5)
      #
      # @example Provide a distance multiplier.
      #   context.geo_near([ 10, 10 ]).distance_multiplier(1133)
      #
      # @param [ Array<Float> ] coordinates The coordinates.
      #
      # @return [ GeoNear ] The GeoNear command.
      #
      # @since 3.1.0
      def geo_near(coordinates)
        GeoNear.new(collection, criteria, coordinates)
      end

      # Invoke the block for each element of Contextual. Create a new array
      # containing the values returned by the block.
      #
      # If the symbol field name is passed instead of the block, additional
      # optimizations would be used.
      #
      # @example Map by some field.
      #   context.map(:field1)
      #
      # @exmaple Map with block.
      #   context.map(&:field1)
      #
      # @param [ Symbol ] field The field name.
      #
      # @return [ Array ] The result of mapping.
      def map(field = nil, &block)
        if block_given?
          super(&block)
        else
          field = field.to_sym
          criteria.only(field).map(&field.to_proc)
        end
      end

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

      delegate(:database_field_name, to: :@klass)

      # Get the last document in the database for the criteria's selector.
      #
      # @example Get the last document.
      #   context.last
      #
      # @return [ Document ] The last document.
      #
      # @since 3.0.0
      def last
        with_inverse_sorting do
          with_eager_loading(query.first)
        end
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
        @length ||= self.count
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

      # Pluck the single field values from the database. Will return duplicates
      # if they exist and only works for top level fields.
      #
      # @example Pluck a field.
      #   context.pluck(:_id)
      #
      # @note This method will return the raw db values - it performs no custom
      #   serialization.
      #
      # @param [ String, Symbol ] field The field to pluck.
      #
      # @return [ Array<Object> ] The plucked values.
      #
      # @since 3.1.0
      def pluck(field)
        normalized = klass.database_field_name(field)
        query.select(normalized => 1).map{ |doc| doc[normalized] }.compact
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
          # update the criteria
          @criteria = criteria.order_by(values)
          apply_option(:sort)
          self
        end
      end

      # Update the first matching document atomically.
      #
      # @example Update the first matching document.
      #   context.update({ "$set" => { name: "Smiths" }})
      #
      # @param [ Hash ] attributes The new attributes for the document.
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

      # Checks if any documents exist in the database.
      #
      # @api private
      #
      # @example Check for document existsence.
      #   context.check_existence
      #
      # @return [ true, false ] If documents exist.
      #
      # @since 3.1.0
      def check_existence
        if cached? && cache_loaded?
          !documents.empty?
        else
          @count ? @count > 0 : !query.dup.select(_id: 1).limit(1).entries.first.nil?
        end
      end

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
        attributes = Hash[attributes.map { |k, v| [klass.database_field_name(k.to_s), v] }]
        query.send(method, attributes.__consolidate__(klass))
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

      # Apply the options.
      #
      # @api private
      #
      # @example Apply all options.
      #   context.apply_options
      #
      # @since 3.1.0
      def apply_options
        apply_fields
        [ :hint, :limit, :skip, :sort, :batch_size, :max_scan ].each do |name|
          apply_option(name)
        end
        if criteria.options[:timeout] == false
          query.no_timeout
        end
      end

      # Apply an option.
      #
      # @api private
      #
      # @example Apply the skip option.
      #   context.apply_option(:skip)
      #
      # @since 3.1.0
      def apply_option(name)
        if spec = criteria.options[name]
          query.send(name, spec)
        end
      end

      # Apply an ascending id sort for use with #first queries, only if no
      # other sorting is provided.
      #
      # @api private
      #
      # @example Apply the id sorting params to the given block
      #   context.with_sorting
      #
      # @since 3.0.0
      def with_sorting
        begin
          unless criteria.options.has_key?(:sort)
            query.sort(_id: 1)
          end
          yield
        ensure
          apply_option(:sort)
        end
      end

      # Map the inverse sort symbols to the correct MongoDB values.
      #
      #  @api private
      #
      # @example Apply the inverse sorting params to the given block
      #   context.with_inverse_sorting
      #
      # @since 3.0.0
      def with_inverse_sorting
        begin
          if spec = criteria.options[:sort]
            query.sort(Hash[spec.map{|k, v| [k, -1*v]}])
          else
            query.sort(_id: -1)
          end
          yield
        ensure
          apply_option(:sort)
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
          Threaded.delete_selection(criteria.object_id)
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
