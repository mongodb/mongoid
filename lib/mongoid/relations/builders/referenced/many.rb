# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Builders #:nodoc:
      module Referenced #:nodoc:
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
            key = metadata.foreign_key
            metadata.klass.all(:conditions => { key => object })
          end
        end
      end
    end
  end
end
