# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:
    # Update is a persistence command responsible for taking a document that
    # has already been saved to the database and saving it, depending on
    # whether or not the document has been modified.
    #
    # Before persisting the command will check via dirty attributes if the
    # document has changed, if not, it will simply return true. If it has it
    # will go through the validation steps, run callbacks, and set the changed
    # fields atomically on the document. The underlying query resembles the
    # following MongoDB query:
    #
    #   collection.update(
    #     { "_id" : "testing" },
    #     { "$set" : { "field" : "value" },
    #     false,
    #     false
    #   );
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
        if @document.changed?
          return false if validate && !@document.valid?
          @document.run_callbacks(:save) do
            if update
              @document.move_changes
            else
              return false
            end
          end
        end; true
      end

      protected
      # Update the document in the database atomically.
      def update
        collection.update(@document.selector, { "$set" => @document.setters }, options)
      end
    end
  end
end
