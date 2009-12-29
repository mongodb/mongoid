# encoding: utf-8
module Mongoid #:nodoc:
  module Commands
    class Delete
      # Performs a delete of the supplied +Document+ without any callbacks.
      #
      # Options:
      #
      # doc: A new +Document+ that is going to be deleted.
      def self.execute(doc)
        parent = doc.parent
        parent ? parent.remove(doc) : doc.collection.remove(:_id => doc.id)
      end
    end
  end
end
