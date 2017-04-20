# encoding: utf-8
module Mongoid
  module Association
    module Referenced
      class HasAndBelongsToMany

        # Builder class for has_and_belongs_to_many associations.
        module Buildable

          # This builder either takes a hash and queries for the
          # object or an array of documents, where it will just return them.
          #
          # @example Build the documents.
          #   Builder.new(association, attrs).build
          #
          # @param [ String ] type The type of document to query for.
          #
          # @return [ Array<Document> ] The documents.
          def build(base, object, type = nil)
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
