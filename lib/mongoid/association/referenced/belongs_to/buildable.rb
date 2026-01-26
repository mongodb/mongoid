# frozen_string_literal: true
# rubocop:todo all

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
          def build(base, object, type = nil, selected_fields = nil)
            return object unless query?(object)
            
            # Handle array from $lookup aggregation (returns array even for belongs_to)
            if object.is_a?(Array)
              first = object.first
              case first
              when nil, Mongoid::Document then return first
              when Hash then return Factory.execute_from_db(klass, first, nil, selected_fields, execute_callbacks: false)
              else raise ArgumentError, "Cannot build belongs_to association from array"
              end
            end
            
            # Handle single hash from $lookup with $unwind
            if object.is_a?(Hash)
              return Factory.execute_from_db(klass, object, nil, selected_fields, execute_callbacks: false)
            end

            execute_query(object, type)
          end

          private

          def execute_query(object, type)
            query_criteria(object, type).take
          end

          def query_criteria(object, type)
            cls = type ? (type.is_a?(String) ? type.constantize : type) : relation_class
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
