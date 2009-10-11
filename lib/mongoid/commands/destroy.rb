module Mongoid #:nodoc:
  module Commands #:nodoc:
    class Destroy #:nodoc:
      # Performs a destroy of the supplied +Document+, with the necessary
      # callbacks. It then deletes the record from the collection.
      #
      # Options:
      #
      # doc: A new +Document+ that is going to be destroyed.
      def self.execute(doc)
        doc.run_callbacks :before_destroy
        doc.collection.remove(:_id => doc.id)
        doc.run_callbacks :after_destroy
      end
    end
  end
end
