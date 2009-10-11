module Mongoid #:nodoc:
  module Commands #:nodoc:
    class Create #:nodoc:
      # Performs a create of the supplied Document, with the necessary
      # callbacks. It then delegates to the Save command.
      #
      # Options:
      #
      # doc: A new +Document+ that is going to be persisted.
      #
      # Returns: +Document+.
      def self.execute(doc)
        doc.run_callbacks :before_create
        Save.execute(doc)
        doc.run_callbacks :after_create
        return doc
      end
    end
  end
end
