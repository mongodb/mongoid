# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Builders #:nodoc:
      module Referenced #:nodoc:
        class Many < Builder

          # This builder either takes a hash and queries for the
          # object or an array of documents, where it will just return tem.
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
            key = @metadata.foreign_key
            @metadata.klass.find(:conditions => { key => @object })
          end
        end
      end
    end
  end
end
