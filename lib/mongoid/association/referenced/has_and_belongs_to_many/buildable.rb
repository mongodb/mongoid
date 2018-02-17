# encoding: utf-8
module Mongoid
  module Association
    module Referenced
      class HasAndBelongsToMany

        # The Builder behavior for has_and_belongs_to_many associations.
        #
        # @since 7.0
        module Buildable

          # This builder either takes a hash and queries for the
          # object or an array of documents, where it will just return them.
          #
          # @example Build the documents.
          #   relation.build(association, attrs)
          #
          # @param [ Object ] base The base object.
          # @param [ Object ] object The object to use to build the relation.
          # @param [ String ] type Not used in this context.
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
