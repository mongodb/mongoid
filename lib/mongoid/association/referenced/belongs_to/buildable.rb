# encoding: utf-8
module Mongoid
  module Association
    module Referenced
      class BelongsTo

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
            return object unless query?(object)
            execute_query(object, type)
          end

          private

          def query_criteria(object, type)
            model = type ? type.constantize : relation_class
            model.where(primary_key => object)
          end

          def execute_query(object, type)
            query_criteria(object, type).limit(-1).first(id_sort: :none)
          end

          def query?(object)
            object && !object.is_a?(Mongoid::Document)
          end
        end
      end
    end
  end
end
