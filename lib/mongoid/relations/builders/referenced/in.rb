# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Builders #:nodoc:
      module Referenced #:nodoc:
        class In < Builder

          # This builder either takes a foreign key and queries for the
          # object or a document, where it will just return it.
          #
          # Example:
          #
          # <tt>Builder.new(meta, attrs).build</tt>
          #
          # Returns:
          #
          # A single +Document+.
          def build
            return @object unless query?
            @metadata.klass.find(@object)
          end
        end
      end
    end
  end
end
