# frozen_string_literal: true

module Mongoid
  module Association
    module Referenced
      class HasAndBelongsToMany
        # The Builder behavior for has_and_belongs_to_many associations.
        module Buildable
          # This builder either takes a hash and queries for the
          # object or an array of documents, where it will just return them.
          #
          # @example Build the documents.
          #   relation.build(association, attrs)
          #
          # @param [ Object ] base The base object.
          # @param [ Object ] object The object to use to build the association.
          # @param [ String ] type Not used in this context.
          # @param [ nil ] selected_fields Must be nil.
          #
          # @return [ Array<Document> ] The documents.
          def build(_base, object, _type = nil, selected_fields = nil)
            if object.is_a?(PreloadedDocuments)
              return build_preloaded(object.documents, selected_fields)
            end

            if query?(object)
              if object.is_a?(Array) && object.empty?
                # An empty stored key array is not $lookup output. Build a none
                # criteria so reset, empty?, and size do not query the database.
                return query_criteria(nil)
              end

              query_criteria(object)
            else
              object.try(:dup)
            end
          end

          private

          # Builds the documents a $lookup preloaded for this association. An
          # empty result builds a none criteria, like an empty key does, so that
          # reset, empty?, and size do not query the database.
          #
          # @param [ Array<Hash> ] documents The preloaded documents.
          # @param [ Hash | nil ] selected_fields Fields which were retrieved via #only.
          #
          # @return [ Array<Document> | Mongoid::Criteria ] The documents.
          def build_preloaded(documents, selected_fields)
            return query_criteria(nil) if documents.empty?

            documents.map do |attrs|
              Factory.execute_from_db(klass, attrs, nil, selected_fields,
                                      execute_callbacks: false)
            end
          end

          def query?(object)
            object.nil? || Array(object).all? { |d| !d.is_a?(Mongoid::Document) }
          end
        end
      end
    end
  end
end
