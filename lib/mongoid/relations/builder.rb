# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:

    # Superclass for all builder objects. Builders are responsible for either
    # looking up a relation's target from the database, or creating them from a
    # supplied attributes hash.
    class Builder

      attr_reader :metadata, :object
      # Instantiate the new builder for a relation.
      #
      # @example Create the builder.
      #   Builder.new(metadata, { :field => "value })
      #
      # @param [ Metdata ] metadata The metadata for the relation.
      # @param [ Hash, BSON::ObjectId ] object The attributes to build from or
      #   id to query with.
      #
      # @since 2.0.0.rc.1
      def initialize(metadata, object)
        @metadata, @object = metadata, object
      end

      protected
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
        return true unless object.respond_to?(:to_a)
        obj = object.to_a.first
        !obj.respond_to?(:attributes) && !obj.nil?
      end
    end
  end
end
