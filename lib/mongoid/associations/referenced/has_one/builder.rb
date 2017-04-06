# encoding: utf-8
module Mongoid
  module Associations
    module Referenced
      class HasOne

        # Builder class for has_one relations.
        #
        # @since 7.0
        class Builder
          include Buildable

          # This builder either takes an _id or an object and queries for the
          # inverse side using the id or sets the object.
          #
          # @example Build the document.
          #   Builder.new(meta, attrs).build
          #
          # @param [ String ] type The type of document to query for.
          #
          # @return [ Document ] A single document.
          def build(type = nil)
            return object unless query?
            return nil if base.new_record?
            association.criteria(association.flag(object), base.class).first
          end
        end
      end
    end
  end
end
