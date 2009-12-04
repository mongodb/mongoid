# encoding: utf-8
module Mongoid #:nodoc:
  module Commands
    class Save
      # Performs a save of the supplied +Document+, handling all associated
      # callbacks and validation.
      #
      # Options:
      #
      # doc: A +Document+ that is going to be persisted.
      #
      # Returns: +Document+ if validation passes, +false+ if not.
      def self.execute(doc)
        return false unless Validate.execute(doc)
        doc.run_callbacks :before_save
        parent = doc.parent
        if parent
          Save.execute(parent)
        else
          collection = doc.collection
          collection ? collection.save(doc.attributes) : raise(MissingParentError.new(doc))
        end
        doc.run_callbacks :after_save
        return doc
      end
    end
  end
end
