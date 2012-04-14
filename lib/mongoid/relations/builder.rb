# encoding: utf-8
module Mongoid
  module Relations

    # Superclass for all builder objects. Builders are responsible for either
    # looking up a relation's target from the database, or creating them from a
    # supplied attributes hash.
    class Builder
      include Threaded::Lifecycle

      attr_reader :base, :metadata, :object

      # Instantiate the new builder for a relation.
      #
      # @example Create the builder.
      #   Builder.new(metadata, { :field => "value })
      #
      # @param [ Document ] base The base document.
      # @param [ Metdata ] metadata The metadata for the relation.
      # @param [ Hash, BSON::ObjectId ] object The attributes to build from or
      #   id to query with.
      #
      # @since 2.0.0.rc.1
      def initialize(base, metadata, object)
        @base, @metadata, @object = base, metadata, object
      end

      protected

      # Get the class from the metadata.
      #
      # @example Get the class.
      #   builder.klass
      #
      # @return [ Class ] The class from the metadata.
      #
      # @since 2.3.2
      def klass
        @klass ||= metadata.klass
      end

      # Do we need to perform a database query? It will be so if the object we
      # have is not a document.
      #
      # @example Should we query the database?
      #   builder.query?
      #
      # @return [ true, false ] Whether a database query should happen.
      #
      # @since 2.0.0.rc.1
      def query?
        obj = object.__array__.first
        !obj.is_a?(Mongoid::Document) && !obj.nil?
      end
    end
  end
end
