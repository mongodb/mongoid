# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Builders #:nodoc:
      module Referenced #:nodoc:
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
            klass, key = metadata.klass, metadata.foreign_key
            loaded = IdentityMap.documents_for(klass).values.detect do |doc|
              doc.send(key) == object
            end
            loaded || klass.where(key => object).first
          end
        end
      end
    end
  end
end
