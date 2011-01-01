# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Builders #:nodoc:
      module Referenced #:nodoc:
        class In < Builder

          # This builder either takes a foreign key and queries for the
          # object or a document, where it will just return it.
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
            begin
              (type ? type.constantize : metadata.klass).find(object)
            rescue Errors::DocumentNotFound
              return nil
            end
          end
        end
      end
    end
  end
end
