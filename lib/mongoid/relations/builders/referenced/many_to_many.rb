# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Builders #:nodoc:
      module Referenced #:nodoc:
        class ManyToMany < Builder

          # This builder either takes a hash and queries for the
          # object or an array of documents, where it will just return them.
          #
          # @example Build the documents.
          #   Builder.new(meta, attrs).build
          #
          # @param [ String ] type The type of document to query for.
          #
          # @return [ Array<Document> ] The documents.
          def build(type = nil)
            return object.dup unless query?
            begin
              metadata.klass.find(object)
            rescue Errors::DocumentNotFound
              return []
            end
          end
        end
      end
    end
  end
end
