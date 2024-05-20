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

      private

      # Retrieves the index records for the indexes with the given names.
      #
      # @param [ Array<String> ] names the index names to query
      #
      # @return [ Array<Hash> ] the raw index documents
      def get_indexes(names)
        collection.search_indexes.select { |i| names.include?(i['name']) }
      end
    end
  end
end
