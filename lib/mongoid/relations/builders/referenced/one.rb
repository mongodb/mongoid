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
            if object.is_a?(Hash)
              return Mongoid::Factory.build(metadata.klass, object)
            end
            metadata.klass.first(
              :conditions => { metadata.foreign_key => object }
            )
          end
        end
      end
    end
  end
end
