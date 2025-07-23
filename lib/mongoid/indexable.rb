# frozen_string_literal: true

require "mongoid/indexable/specification"
require "mongoid/indexable/validators/options"
require "ostruct"

module Mongoid

  # Encapsulates behavior around defining indexes.
  module Indexable
    extend ActiveSupport::Concern

    included do
      cattr_accessor :index_specifications
      self.index_specifications = []
    end

    module ClassMethods

      # Send the actual index creation comments to the MongoDB driver
      #
      # @example Create the indexes for the class.
      #   Person.create_indexes
      #
      # @return [ true ] If the operation succeeded.
      def create_indexes
        return unless index_specifications

        default_options = {background: Config.background_indexing}

        index_specifications.each do |spec|
          key, options = spec.key, default_options.merge(spec.options)
          if database = options[:database]
            with(database: database) do |klass|
              klass.collection.indexes(session: _session).create_one(key, options.except(:database))
            end
          else
            collection.indexes(session: _session).create_one(key, options)
          end
        end and true
      end

      # Send the actual index removal comments to the MongoDB driver,
      # but lets _id untouched.
      #
      # @example Remove the indexes for the class.
      #   Person.remove_indexes
      #
      # @return [ true ] If the operation succeeded.
      def remove_indexes
        indexed_database_names.each do |database|
          with(database: database) do |klass|
            begin
              klass.collection.indexes(session: _session).each do |spec|
                unless spec["name"] == "_id_"
                  klass.collection.indexes(session: _session).drop_one(spec["key"])
                  logger.info(
                    "MONGOID: Removed index '#{spec["name"]}' on collection " +
                    "'#{klass.collection.name}' in database '#{database}'."
                  )
                end
              end
            rescue Mongo::Error::OperationFailure; end
          end
        end and true
      end

      # Add the default indexes to the root document if they do not already
      # exist. Currently this is only _type.
      #
      # @example Add Mongoid internal indexes.
      #   Person.add_indexes
      #
      # @return [ true ] If the operation succeeded.
      def add_indexes
        if hereditary? && !index_keys.include?(self.discriminator_key.to_sym => 1)
          index({ self.discriminator_key.to_sym => 1 }, unique: false, background: true)
        end
        true
      end

      # Adds an index definition for the provided single or compound keys.
      #
      # @example Create a basic index.
      #   class Person
      #     include Mongoid::Document
      #     field :name, type: String
      #     index({ name: 1 }, { background: true })
      #   end
      #
      # @param [ Hash ] spec The index spec.
      # @param [ Hash ] options The index options.
      #
      # @return [ Hash ] The index options.
      def index(spec, options = nil)
        specification = Specification.new(self, spec, options)
        if !index_specifications.include?(specification)
          index_specifications.push(specification)
        end
      end

      # Get an index specification for the provided key.
      #
      # @example Get the index specification.
      #   Model.index_specification(name: 1)
      #
      # @param [ Hash ] index_hash The index key/direction pair.
      # @param [ String ] index_name The index name.
      #
      # @return [ Specification ] The found specification.
      def index_specification(index_hash, index_name = nil)
        index = OpenStruct.new(fields: index_hash.keys, key: index_hash)
        index_specifications.detect do |spec|
          spec == index || (index_name && index_name == spec.name)
        end
      end

      private

      # Get the names of all databases for this model that have index
      # definitions.
      #
      # @api private
      #
      # @example Get the indexed database names.
      #   Model.indexed_database_names
      #
      # @return [ Array<String> ] The names.
      def indexed_database_names
        index_specifications.map do |spec|
          spec.options[:database] || database_name
        end.uniq
      end

      # Gets a list of index specification keys.
      #
      # @api private
      #
      # @example Get the specification key list.
      #   Model.index_keys
      #
      # @return [ Array<Hash> ] The specification keys.
      def index_keys
        index_specifications.map(&:key)
      end
    end
  end
end
