# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    class OneToMany < Proxy

      protected

      # Appends the document to the target array, updating the index on the
      # document at the same time.
      #
      # Example:
      #
      # <tt>relation.append(document)</tt>
      #
      # Options:
      #
      # document: The document to append to the target.
      def append(document)
        @target << document
        document._index = @target.size - 1
      end
    end
  end
end
