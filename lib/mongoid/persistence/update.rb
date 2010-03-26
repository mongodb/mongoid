# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:
    class Update #:nodoc:

      attr_reader :collection, :document, :options, :validate

      # Create the new update persister.
      #
      # Options:
      #
      # document: The +Document+ to persist.
      # validate: +Boolean+ to validate or not.
      #
      # Example:
      #
      # <tt>Update.new(document)</tt>
      def initialize(document, validate = true)
        @collection = document.collection
        @document = document
        @validate = validate
        @options = { :multi => false, :safe => Mongoid.persist_in_safe_mode }
      end

      # Persist the document that is to be updated to the database. This will
      # only write changed fields via MongoDB's $set modifier operation.
      #
      # Example:
      #
      # <tt>Update.persist</tt>
      #
      # Returns:
      #
      # +true+ or +false+, depending on validation.
      def persist
        if document.changed?
          return false if validate && !document.valid?
          document.run_callbacks(:save) do
            if update
              document.move_changes
            else
              return false
            end
          end
        end; true
      end

      protected
      # Update the document in the database atomically.
      def update
        collection.update(document.selector, { "$set" => document.new_values }, options)
      end
    end
  end
end
