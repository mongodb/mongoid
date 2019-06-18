# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Association
    module Referenced
      class BelongsTo

        # The Builder behavior for belongs_to associations.
        #
        # @since 7.0
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
          def build(base, object, type = nil, selected_fields = nil)
            return object unless query?(object)
            execute_query(object, type)
          end

          private

          def execute_query(object, type)
            query_criteria(object, type).limit(-1).first(id_sort: :none)
          end

          def query_criteria(object, type)
            model = type ? type.constantize : relation_class
            model.where(primary_key => object)
          end

          def query?(object)
            object && !object.is_a?(Mongoid::Document)
          end
        end
      end
    end
  end
end
