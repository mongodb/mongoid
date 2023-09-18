# frozen_string_literal: true

module Mongoid
  # Encapsulates behavior around managing search indexes. This feature
  # is only supported when connected to an Atlas cluster.
  module SearchIndexable
    extend ActiveSupport::Concern

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

      def search_indexes(options = {})
        collection.search_indexes(options)
      end

      def remove_search_index(name: nil, id: nil)
        logger.info(
          "MONGOID: Removing search index '#{name || id}' " \
          "on collection '#{collection.name}'."
        )

        collection.search_indexes.drop_one(name: name, id: id)
      end

      # Request the removal of all registered search indices. Note
      # that the search indexes are removed asynchronously, and may take
      # several minutes to be fully deleted.
      #
      # @note It would be nice if this could remove ONLY the search indices
      # that have been declared on the model, but because the model may not
      # name the index, we can't guarantee that we'll know the name or id of
      # the corresponding indices. It is not unreasonable to assume, though,
      # that the intention is for the model to declare, one-to-one, all
      # desired search indices, so removing all search indices ought to suffice.
      # If a specific index or set of indices needs to be removed instead,
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
      # @param [ Symbol | String ] name_or_defn Either the name of the index to
      #    define, or the index definition.
      # @param [ Hash ] defn The search index definition.
      def search_index(name_or_defn, defn = nil)
        name = name_or_defn
        name, defn = nil, name if name.is_a?(Hash)

        spec = { definition: defn }.tap { |s| s[:name] = name if name }
        search_index_specs.push(spec)
      end
    end
  end
end
