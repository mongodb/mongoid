# encoding: utf-8
require "mongoid/contextual/aggregable/memory"

module Mongoid
  module Contextual
    class Memory
      include Enumerable
      include Aggregable::Memory
      include Eager
      include Queryable
      include Mongoid::Atomic::Positionable

      # @attribute [r] root The root document.
      # @attribute [r] path The atomic path.
      # @attribute [r] selector The root document selector.
      # @attribute [r] matching The in memory documents that match the selector.
      attr_reader :documents, :path, :root, :selector

      # Check if the context is equal to the other object.
      #
      # @example Check equality.
      #   context == []
      #
      # @param [ Array ] other The other array.
      #
      # @return [ true, false ] If the objects are equal.
      #
      # @since 3.0.0
      def ==(other)
        return false unless other.respond_to?(:entries)
        entries == other.entries
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
        deleted = count
        removed = map do |doc|
          prepare_remove(doc)
          doc.as_document
        end
        unless removed.empty?
          collection.find(selector).update(
            positionally(selector, "$pullAll" => { path => removed })
          )
        end
        deleted
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
        deleted = count
        each do |doc|
          documents.delete_one(doc)
          doc.destroy
        end
        deleted
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
        documents.map{ |doc| doc.send(field) }.uniq
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
          documents_for_iteration.each do |doc|
            yield(doc)
          end
          # eager_loadable? ? docs : self
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

      # Get the first document in the database for the criteria's selector.
      #
      # @example Get the first document.
      #   context.first
      #
      # @return [ Document ] The first document.
      #
      # @since 3.0.0
      def first
        doc = documents.first
        eager_load_one(doc) if eager_loadable?(doc)
        doc
      end
      alias :one :first

      # Create the new in memory context.
      #
      # @example Create the new context.
      #   Memory.new(criteria)
      #
      # @param [ Criteria ] The criteria.
      #
      # @since 3.0.0
      def initialize(criteria)
        @criteria, @klass = criteria, criteria.klass
        @documents = criteria.documents.select do |doc|
          @root ||= doc._root
          @collection ||= root.collection
          doc.matches?(criteria.selector)
        end
        apply_sorting
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
        doc = documents.last
        eager_load_one(doc) if eager_loadable?(doc)
        doc
      end

      # Get the length of matching documents in the context.
      #
      # @example Get the length of matching documents.
      #   context.length
      #
      # @return [ Integer ] The matching length.
      #
      # @since 3.0.0
      def length
        documents.length
      end
      alias :size :length

      # Limits the number of documents that are returned.
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
        self.limiting = value
        self
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
        self.skipping = value
        self
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
        in_place_sort(values) and self
      end

      # Update the first matching document atomically.
      #
      # @example Update the matching document.
      #   context.update(name: "Smiths")
      #
      # @param [ Hash ] attributes The new attributes for the document.
      #
      # @return [ nil, false ] False if no attributes were provided.
      #
      # @since 3.0.0
      def update(attributes = nil)
        update_documents(attributes, [ first ])
      end

      # Update all the matching documents atomically.
      #
      # @example Update all the matching documents.
      #   context.update_all(name: "Smiths")
      #
      # @param [ Hash ] attributes The new attributes for each document.
      #
      # @return [ nil, false ] False if no attributes were provided.
      #
      # @since 3.0.0
      def update_all(attributes = nil)
        update_documents(attributes, entries)
      end

      private

      # Get the documents the context should iterate. This follows 3 rules:
      #
      # @api private
      #
      # @example Get the documents for iteration.
      #   context.documents_for_iteration
      #
      # @return [ Array<Document> ] The docs to iterate.
      #
      # @since 3.1.0
      def documents_for_iteration
        docs = documents[skipping || 0, limiting || documents.length] || []
        if eager_loadable?
          eager_load(docs)
        end
        docs
      end

      # Update the provided documents with the attributes.
      #
      # @api private
      #
      # @example Update the documents.
      #   context.update_documents({}, doc)
      #
      # @param [ Hash ] attributes The attributes.
      # @param [ Array<Document> ] docs The docs to update.
      #
      # @since 3.0.4
      def update_documents(attributes, docs)
        return false if !attributes || docs.empty?
        updates = { "$set" => {}}
        docs.each do |doc|
          @selector ||= root.atomic_selector
          doc.write_attributes(attributes)
          updates["$set"].merge!(doc.atomic_updates["$set"] || {})
          doc.move_changes
        end
        collection.find(selector).update(updates)
      end

      # Get the limiting value.
      #
      # @api private
      #
      # @example Get the limiting value.
      #
      # @return [ Integer ] The limit.
      #
      # @since 3.0.0
      def limiting
        defined?(@limiting) ? @limiting : nil
      end

      # Set the limiting value.
      #
      # @api private
      #
      # @example Set the limiting value.
      #
      # @param [ Integer ] value The limit.
      #
      # @return [ Integer ] The limit.
      #
      # @since 3.0.0
      def limiting=(value)
        @limiting = value
      end

      # Get the skiping value.
      #
      # @api private
      #
      # @example Get the skiping value.
      #
      # @return [ Integer ] The skip.
      #
      # @since 3.0.0
      def skipping
        defined?(@skipping) ? @skipping : nil
      end

      # Set the skiping value.
      #
      # @api private
      #
      # @example Set the skiping value.
      #
      # @param [ Integer ] value The skip.
      #
      # @return [ Integer ] The skip.
      #
      # @since 3.0.0
      def skipping=(value)
        @skipping = value
      end

      # Apply criteria options.
      #
      # @api private
      #
      # @example Apply criteria options.
      #   context.apply_options
      #
      # @return [ Memory ] self.
      #
      # @since 3.0.0
      def apply_options
        skip(criteria.options[:skip]).limit(criteria.options[:limit])
      end

      # Map the sort symbols to the correct MongoDB values.
      #
      # @example Apply the sorting params.
      #   context.apply_sorting
      #
      # @since 3.0.0
      def apply_sorting
        if spec = criteria.options[:sort]
          in_place_sort(spec)
        end
      end

      # Compare two values, checking for nil.
      #
      # @api private
      #
      # @example Compare the two objects.
      #   context.compare(a, b)
      #
      # @param [ Object ] a The first object.
      # @param [ Object ] b The first object.
      #
      # @return [ Integer ] The comparison value.
      #
      # @since 3.0.0
      def compare(a, b)
        case
        when a.nil? then b.nil? ? 0 : 1
        when b.nil? then -1
        else a <=> b
        end
      end

      # Sort the documents in place.
      #
      # @example Sort the documents.
      #   context.in_place_sort(name: 1)
      #
      # @param [ Hash ] values The field/direction sorting pairs.
      #
      # @since 3.0.0
      def in_place_sort(values)
        values.keys.reverse.each do |field|
          documents.sort! do |a, b|
            a_value, b_value = a[field], b[field]
            value = compare(a_value.__sortable__, b_value.__sortable__)
            values[field] < 0 ? value * -1 : value
          end
        end
      end

      # Prepare the document for batch removal.
      #
      # @api private
      #
      # @example Prepare for removal.
      #   context.prepare_remove(doc)
      #
      # @param [ Document ] doc The document.
      #
      # @since 3.0.0
      def prepare_remove(doc)
        @selector ||= root.atomic_selector
        @path ||= doc.atomic_path
        documents.delete_one(doc)
        doc._parent.remove_child(doc)
        doc.destroyed = true
      end
    end
  end
end
