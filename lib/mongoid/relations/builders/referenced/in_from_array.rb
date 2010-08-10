# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Builders #:nodoc:
      module Referenced #:nodoc:
        class InFromArray < Builder

          # This builder either takes a hash and queries for the
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
            key = @metadata.foreign_key
            @metadata.klass.any_in(key => [ @object["_id" ] ]).first
          end
        end
      end
    end
  end
end
