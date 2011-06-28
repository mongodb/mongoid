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
    #     { "_id" : 1,
    #     { "$set" : { "field" : "value" },
    #     false,
    #     false
    #   );
    #
    # For embedded documents it will use the positional locator:
    #
    #   collection.update(
    #     { "_id" : 1, "addresses._id" : 2 },
    #     { "$set" : { "addresses.$.field" : "value" },
    #     false,
    #     false
    #   );
    #
    class Update < Command

      # Persist the document that is to be updated to the database. This will
      # only write changed fields via MongoDB's $set modifier operation.
      #
      # @example Update the document.
      #   Update.persist
      #
      # @return [ true, false ] If the save passed.
      def persist
        return false if validate && document.invalid?(:update)
        value = document.run_callbacks(:save) do
          document.run_callbacks(:update) { update }
        end
        document.move_changes
        document._children.each do |child|
          child.move_changes
          child.new_record = false
        end
        return value
      end

      protected

      # Update the document in the database atomically.
      #
      # @example Update the document.
      #   command.update
      #
      # @return [ true ] Always true.
      def update
        updates = document.atomic_updates
        unless updates.empty?
          others = updates.delete(:other)
          selector = document._selector
          collection.update(selector, updates, options.merge!(:multi => false))
          if others
            collection.update(
              selector,
              { "$pushAll" => others },
              options.merge!(:multi => false)
            )
          end
        end
        return true
      end
    end
  end
end
