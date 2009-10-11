module Mongoid #:nodoc:
  module Commands #:nodoc:
    class Delete #:nodoc:
      # Performs a delete of the supplied +Document+ without any callbacks.
      #
      # Options:
      #
      # doc: A new +Document+ that is going to be deleted.
      def self.execute(doc)
        doc.collection.remove(:_id => doc.id)
      end
    end
  end
end
