# encoding: utf-8
module Mongoid
  module Association
    module Referenced
      class HasMany

        module Buildable

          # This builder either takes an _id or an object and queries for the
          # inverse side using the id or sets the object.
          #
          # @example Build the document.
          #   Builder.new(meta, attrs).build
          #
          # @param [ String ] type The type of document to query for.
          #
          # @return [ Document ] A single document.
          def build(base, object, type = nil)
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
