module Mongoid #:nodoc:
  module Commands #:nodoc:
    class Save #:nodoc:
      # Performs a save of the supplied Document, handling all associated
      # callbacks and validation.
      #
      # Options:
      #
      # doc: A +Document+ that is going to be persisted.
      #
      # Returns: +Document+ if validation passes, +false+ if not.
      def self.execute(doc)
        return false unless doc.valid?
        doc.run_callbacks :before_save
        doc.run_callbacks :after_save
      end
    end
  end
end
