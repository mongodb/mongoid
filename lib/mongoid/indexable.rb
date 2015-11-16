# encoding: utf-8
require "mongoid/indexable/specification"
require "mongoid/indexable/validators/options"
require "ostruct"

module Mongoid

  # Encapsulates behaviour around defining indexes.
  #
  # @since 4.0.0
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
      #
      # @since 1.0.0
      def create_indexes
        return unless index_specifications
        index_specifications.each do |spec|
          key, options = spec.key, spec.options
          if database = options[:database]
            with(database: database).
              collection.indexes.create_one(key, options.except(:database))
          else
            collection.indexes.create_one(key, options)
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
      #
      # @since 3.0.0
      def remove_indexes
        indexed_database_names.each do |database|
          collection = with(database: database).collection
          begin
            collection.indexes.each do |spec|
              unless spec["name"] == "_id_"
                collection.indexes.drop_one(spec["key"])
                logger.info(
                  "MONGOID: Removed index '#{spec["name"]}' on collection " +
                  "'#{collection.name}' in database '#{database}'."
                )
              end
            end
          rescue Mongo::Error::OperationFailure; end
        end and true
      end

      # Add the default indexes to the root document if they do not already
      # exist. Currently this is only _type.
      #
      # @example Add Mongoid internal indexes.
      #   Person.add_indexes
      #
      # @return [ true ] If the operation succeeded.
      #
      # @since 1.0.0
      def add_indexes
        if hereditary? && !index_keys.include?(_type: 1)
          index({ _type: 1 }, unique: false, background: true)
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
      # @param [ Symbol ] name The name of the field.
      # @param [ Hash ] options The index options.
      #
      # @return [ Hash ] The index options.
      #
      # @since 1.0.0
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
      # @param [ Hash ] key The index key/direction pair.
      #
      # @return [ Specification ] The found specification.
      #
      # @since 4.0.0
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
      #
      # @since 3.1.0
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
      #
      # @since 4.0.0
      def index_keys
        index_specifications.map(&:key)
      end
    end
  end
end
