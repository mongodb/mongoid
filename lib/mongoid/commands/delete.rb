# encoding: utf-8
module Mongoid #:nodoc:
  module Commands
    class Delete
      extend Deletion
      # Performs a delete of the supplied +Document+ without any callbacks.
      #
      # Options:
      #
      # doc: A new +Document+ that is going to be deleted.
      def self.execute(doc)
        delete(doc)
      end
    end
  end
end
