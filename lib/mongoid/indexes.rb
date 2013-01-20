# encoding: utf-8
require "mongoid/indexes/validators/options"

module Mongoid
  module Indexes
    extend ActiveSupport::Concern

    included do
      cattr_accessor :index_options
      self.index_options = {}
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
        return unless index_options
        index_options.each_pair do |spec, options|
          if database = options[:database]
            with(consistency: :strong, database: database).
              collection.indexes.create(spec, options.except(:database))
          else
            with(consistency: :strong).collection.indexes.create(spec, options)
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
          collection = with(consistency: :strong, database: database).collection
          collection.indexes.each do |spec|
            unless spec["name"] == "_id_"
              collection.indexes.drop(spec["key"])
            end
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
      #
      # @since 1.0.0
      def add_indexes
        if hereditary? && !index_options[{ _type: 1 }]
          index({ _type: 1 }, { unique: false, background: true })
        end
        true
      end

      # Adds an index on the field specified. Options can be :unique => true or
      # :unique => false. It will default to the latter.
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
        Validators::Options.validate(self, spec, options || {})
        index_options[normalize_spec(spec)] = normalize_index_options(options)
      end

      private

      # Normalize the index options, if any are provided.
      #
      # @api private
      #
      # @example Normalize the index options.
      #   Model.normalize_index_options(drop_dups: true)
      #
      # @param [ Hash ] options The index options.
      #
      # @return [ Hash ] The normalized options.
      #
      # @since 3.0.0
      def normalize_index_options(options)
        opts = options || {}
        opts[:dropDups] = opts.delete(:drop_dups) if opts.has_key?(:drop_dups)
        opts[:bucketSize] = opts.delete(:bucket_size) if opts.has_key?(:bucket_size)
        if opts.has_key?(:expire_after_seconds)
          opts[:expireAfterSeconds] = opts.delete(:expire_after_seconds)
        end
        opts
      end

      # Normalize the spec, in case aliased fields are provided.
      #
      # @api private
      #
      # @example Normalize the spec.
      #   Model.normalize_spec(name: 1)
      #
      # @param [ Hash ] spec The index specification.
      #
      # @return [ Hash ] The normalized specification.
      #
      # @since 3.0.7
      def normalize_spec(spec)
        spec.inject({}) do |normalized, (name, direction)|
          normalized[database_field_name(name).to_sym] = direction
          normalized
        end
      end

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
        index_options.values.map do |options|
          options[:database] || database_name
        end.uniq
      end
    end
  end
end
