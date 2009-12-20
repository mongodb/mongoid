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
        return false unless doc.valid?
        doc.run_callbacks :before_save
        parent = doc.parent
        doc.new_record = false
        parent ? Save.execute(parent) : doc.collection.save(doc.attributes)
        doc.run_callbacks :after_save
        return true
      end
    end
  end
end
