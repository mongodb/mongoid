# encoding: utf-8
module Mongoid #:nodoc:
  module Commands
    class Destroy
      extend Deletion
      # Performs a destroy of the supplied +Document+, with the necessary
      # callbacks. It then deletes the record from the collection.
      #
      # Options:
      #
      # doc: A new +Document+ that is going to be destroyed.
      def self.execute(doc)
        doc.run_callbacks(:destroy) { delete(doc) }
      end
    end
  end
end
