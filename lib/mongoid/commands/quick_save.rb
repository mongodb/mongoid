# encoding: utf-8
module Mongoid #:nodoc:
  module Commands
    class QuickSave
      # Performs a save of the supplied +Document+ without any validations or
      # callbacks. This is a dangerous command only intended for internal use
      # with saving relational associations.
      #
      # Options:
      #
      # doc: A +Document+ that is going to be persisted.
      #
      # Returns: true
      def self.execute(doc)
        doc.collection.save(doc.attributes)
      end
    end
  end
end
