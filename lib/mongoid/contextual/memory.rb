# encoding: utf-8
require "mongoid/contextual/aggregable/memory"

module Mongoid #:nodoc:
  module Contextual
    class Memory
      include Enumerable
      include Aggregable::Memory

      # @attribute [r] criteria The criteria for the context.
      # @attribute [r] klass The criteria class.
      # @attribute [r] matching The in memory documents that match the
      #   selector.
      attr_reader :criteria, :klass, :documents

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

      # Delete all documents in the database that match the selector.
      #
      # @example Delete all the documents.
      #   context.delete
      #
      # @return [ nil ] Nil.
      #
      # @since 3.0.0
      def delete
        # @todo: Durran: Optimize to a single db call.
        count.tap do
          each do |doc|
            documents.delete_one(doc)
            doc.delete
          end
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
        # @todo: Durran: Optimize to a single db call.
        count.tap do
          each do |doc|
            documents.delete_one(doc)
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
          documents[skipping || 0, limiting || documents.length].each do |doc|
            yield doc
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

      # Get the first document in the database for the criteria's selector.
      #
      # @example Get the first document.
      #   context.first
      #
      # @return [ Document ] The first document.
      #
      # @since 3.0.0
      def first
        documents.first
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
          doc.matches?(criteria.selector)
        end
        apply_sorting
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
        documents.last
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
        self.limiting = value and self
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
        self.skipping = value and self
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
        # @todo: Durran: Optimize to a single db call.
        return false unless attributes
        each do |doc|
          doc.update_attributes(attributes)
        end
      end
      alias :update_all :update

      private

      # @attribute [rw] limiting The number of documents to return.
      # @attribute [rw] skipping The number of documents to skip.
      attr_accessor :limiting, :skipping

      # Map the sort symbols to the correct MongoDB values.
      SORT_MAPPINGS = { asc: 1, ascending: 1, desc: -1, descending: -1 }

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
          normalized = Hash[spec]
          normalized.each_pair do |field, direction|
            unless direction.is_a?(::Integer)
              normalized[field] = SORT_MAPPINGS[direction.to_sym]
            end
          end
          in_place_sort(normalized)
        end
      end

      # Sort the documents in place.
      #
      # @todo: Durran: Temporary until sorting is all refactored.
      #
      # @example Sort the documents.
      #   context.in_place_sort(name: 1)
      #
      # @param [ Hash ] values The field/direction sorting pairs.
      #
      # @since 3.0.0
      def in_place_sort(values)
        values.each_pair do |field, dir|
          documents.sort! do |a, b|
            dir > 0 ? a[field] <=> b[field] : b[field] <=> a[field]
          end
        end
      end
    end
  end
end
