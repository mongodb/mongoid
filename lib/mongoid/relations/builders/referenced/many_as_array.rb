# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Builders #:nodoc:
      module Referenced #:nodoc:
        class ManyAsArray < Builder

          # This builder either takes a hash and queries for the
          # object or an array of documents, where it will just return them.
          #
          # Example:
          #
          # <tt>Builder.new(meta, attrs).build</tt>
          #
          # Returns:
          #
          # An array of documents.
          def build
            return @object unless query?
            @metadata.klass.find(@object[@metadata.foreign_key])
          end
        end
      end
    end
  end
end
