# encoding: utf-8
require "mongoid/indexes/validators/options"

module Mongoid #:nodoc
  module Indexes #:nodoc
    extend ActiveSupport::Concern

    included do
      cattr_accessor :index_options
      self.index_options = {}
    end

    module ClassMethods #:nodoc

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
          collection.indexes.create(spec, options)
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
        collection.indexes.each do |spec|
          next if spec["name"] == "_id_"
          collection.indexes.drop(spec["key"])
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
          index _type: 1, options: { unique: false, background: true }
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
      #     index name: 1, options: { background: true }
      #   end
      #
      # @param [ Symbol ] name The name of the field.
      # @param [ Hash ] options The index options.
      #
      # @return [ Hash ] The index options.
      #
      # @since 1.0.0
      def index(spec)
        Validators::Options.validate(self, spec)
        index_options[spec] = normalize_index_options(spec)
      end

      private

      # Normalize the index options, if any are provided.
      #
      # @api private
      #
      # @example Normalize the index options.
      #   Model.normalize_index_options(name: 1)
      #
      # @param [ Hash ] spec The index specification.
      #
      # @return [ Hash ] The normalized options.
      #
      # @since 3.0.0
      def normalize_index_options(spec)
        opts = (spec.delete(:options) || {})
        opts[:dropDups] = opts.delete(:drop_dups) if opts.has_key?(:drop_dups)
        opts
      end
    end
  end
end
