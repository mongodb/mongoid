# frozen_string_literal: true

module Mongoid
  module Association
    module Referenced
      class HasMany

        # The Builder behavior for has_many associations.
        module Buildable

          # This method either takes an _id or an object and queries for the
          # inverse side using the id or sets the object.
          #
          # @example Build the document.
          #   relation.build(meta, attrs)
          #
          # @param [ Object ] base The base object.
          # @param [ Object ] object The object to use to build the association.
          # @param [ String ] type The type of document to query for.
          # @param [ nil ] selected_fields Must be nil.
          #
          # @return [ Document ] A single document.
          def build(base, object, type = nil, selected_fields = nil)
            return (object || []) unless query?(object)
            return [] if object.is_a?(Array)
            query_criteria(object, base)
          end

          private

          def query?(object)
            object && Array(object).all? { |d| !d.is_a?(Mongoid::Document) }
          end
        end
      end
    end
  end
end
