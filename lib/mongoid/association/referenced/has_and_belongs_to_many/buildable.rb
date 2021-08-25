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
          def build(base, object, type = nil, selected_fields = nil)
            if query?(object)
              query_criteria(object)
            else
              object.try(:dup)
            end
          end

          private

          def query?(object)
            object.nil? || Array(object).all? { |d| !d.is_a?(Mongoid::Document) }
          end
        end
      end
    end
  end
end
