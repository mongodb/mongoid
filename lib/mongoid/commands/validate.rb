# encoding: utf-8
module Mongoid #:nodoc:
  module Commands
    class Validate
      # Performs validation of the supplied +Document+, handling all associated
      # callbacks.
      #
      # Options:
      #
      # doc: A +Document+ that is going to be persisted.
      #
      # Returns: +true+ if validation passes, +false+ if not.
      def self.execute(doc)
        doc.run_callbacks(:before_validation)
        validated = doc.valid?
        doc.run_callbacks(:after_validation)
        return validated
      end
    end
  end
end
