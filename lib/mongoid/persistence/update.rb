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
      # Example:
      #
      # <tt>Update.persist</tt>
      #
      # Returns:
      #
      # +true+ or +false+, depending on validation.
      def persist
        return false if validate && document.invalid?(:update)
        document.run_callbacks(:save) do
          document.run_callbacks(:update) do
            if update
              document.move_changes
              document._children.each do |child|
                child.move_changes
                child.new_record = false if child.new_record?
              end
            else
              return false
            end
          end
        end; true
      end

      protected
      # Update the document in the database atomically.
      def update
        updates = document._updates
        unless updates.empty?
          other_pushes = updates.delete(:other)
          collection.update(document._selector, updates, options.merge(:multi => false))
          collection.update(
            document._selector,
            { "$pushAll" => other_pushes },
            options.merge(:multi => false)
          ) if other_pushes
        end; true
      end
    end
  end
end
