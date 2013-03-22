# encoding: utf-8
module Mongoid
  module Relations
    module Builders
      module Referenced
        class Many < Builder

          # This builder either takes a hash and queries for the
          # object or an array of documents, where it will just return tem.
          #
          # @example Build the documents.
          #   Builder.new(meta, attrs).build
          #
          # @param [ String ] type The type of document to query for.
          #
          # @return [ Array<Document> ] The documents.
          def build(type = nil)
            return object unless query?
            return [] if object.is_a?(Array)
            crit = metadata.criteria(Conversions.flag(object, metadata), base.class)
            IdentityMap.get_many(crit.klass, crit.send(:selector_with_type_selection)) || crit
          end
        end
      end
    end
  end
end
