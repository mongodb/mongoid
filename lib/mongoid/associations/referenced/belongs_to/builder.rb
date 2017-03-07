# encoding: utf-8
module Mongoid
  module Associations
    module Referenced
      class BelongsTo

        # Builder class for belongs_to associations.
        class Builder
          include Buildable

          # This builder either takes a foreign key and queries for the
          # object or a document, where it will just return it.
          #
          # @example Build the document.
          #   Builder.new(meta, attrs).build
          #
          # @param [ String ] type The type of document to query for.
          #
          # @return [ Document ] A single document.
          #
          # @since 7.0
          def build(type = nil)
            return object unless query?
            model = type ? type.constantize : metadata.klass
            metadata.criteria(object, model).first
          end
        end
      end
    end
  end
end
