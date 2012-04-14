# encoding: utf-8
module Mongoid
  module Relations
    module Builders
      module Referenced
        class One < Builder

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
            metadata.criteria(Conversions.flag(object, metadata), base.class).from_map_or_db
          end
        end
      end
    end
  end
end
