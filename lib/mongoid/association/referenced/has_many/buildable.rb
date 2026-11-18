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
          def build(base, object, _type = nil, selected_fields = nil)
            if object.is_a?(PreloadedDocuments)
              return build_preloaded(object.documents, selected_fields)
            end

            return object || [] unless query?(object)

            return [] if object.is_a?(Array)

            query_criteria(object, base)
          end

          private

          # Builds the documents a $lookup preloaded for this association.
          #
          # @param [ Array<Hash> ] documents The preloaded documents.
          # @param [ Hash | nil ] selected_fields Fields which were retrieved via #only.
          #
          # @return [ Array<Document> ] The built documents.
          def build_preloaded(documents, selected_fields)
            documents.map do |attrs|
              Factory.execute_from_db(klass, attrs, nil, selected_fields,
                                      execute_callbacks: false)
            end
          end

          def query?(object)
            object && Array(object).all? { |d| !d.is_a?(Mongoid::Document) }
          end
        end
      end
    end
  end
end
