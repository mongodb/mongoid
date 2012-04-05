# encoding: utf-8
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
      # @since 1.0.0
      def create_indexes
        return unless index_options
        index_options.each_pair do |spec, options|
          collection.indexes.create(spec, options)
        end
      end

      # Send the actual index removal comments to the MongoDB driver,
      # but lets _id untouched.
      #
      # @example Remove the indexes for the class.
      #   Person.remove_indexes
      #
      # @since 3.0.0
      def remove_indexes
        collection.indexes.each do |spec|
          next if spec["name"] == "_id_"
          collection.indexes.drop(spec["key"])
        end
      end

      # Add the default indexes to the root document if they do not already
      # exist. Currently this is only _type.
      #
      # @example Add Mongoid internal indexes.
      #   Person.add_indexes
      #
      # @since 1.0.0
      def add_indexes
        if hereditary? && !index_options[{ _type: 1 }]
          index _type: 1, options: { unique: false, background: true }
        end
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
      # @since 1.0.0
      def index(spec)
        # @todo: Durran: Validate options.
        options = spec.delete(:options)
        index_options[spec] = { unique: false }.merge(options || {})
      end
    end
  end
end
