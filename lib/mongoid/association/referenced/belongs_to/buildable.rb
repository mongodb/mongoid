# frozen_string_literal: true

module Mongoid
  module Association
    module Referenced
      class BelongsTo
        # The Builder behavior for belongs_to associations.
        module Buildable
          # This method either takes an _id or an object and queries for the
          # inverse side using the id or sets the object.
          #
          # @example Build the document.
          #   relation.build(meta, attrs)
          #
          # @param [ Object ] base The base object.
          # @param [ Object ] object The object to use to build the association.
          # @param [ String ] type The type of the association.
          # @param [ nil ] selected_fields Must be nil.
          #
          # @return [ Document ] A single document.
          def build(_base, object, type = nil, selected_fields = nil)
            if object.is_a?(PreloadedDocuments)
              return build_preloaded(object.documents, selected_fields)
            end

            return object unless query?(object)

            execute_query(object, type)
          end

          private

          # Builds the document from the documents a $lookup preloaded for this
          # association. The lookup returns an array, even for belongs_to, and
          # may be unwound to a single document.
          #
          # @param [ Array<Hash> | Hash | nil ] documents The preloaded documents.
          # @param [ Hash | nil ] selected_fields Fields which were retrieved via #only.
          #
          # @return [ Document | nil ] The built document.
          def build_preloaded(documents, selected_fields)
            document = documents.is_a?(Array) ? documents.first : documents
            return document if document.nil? || document.is_a?(Mongoid::Document)

            Factory.execute_from_db(klass, document, nil, selected_fields,
                                    execute_callbacks: false)
          end

          def execute_query(object, type)
            query_criteria(object, type).take
          end

          def query_criteria(object, type)
            cls = if type
                    type.is_a?(String) ? type.constantize : type
                  else
                    relation_class
                  end
            crit = cls.criteria
            crit = crit.apply_scope(scope)
            crit.where(primary_key => object)
          end

          def query?(object)
            object && !object.is_a?(Mongoid::Document)
          end
        end
      end
    end
  end
end
