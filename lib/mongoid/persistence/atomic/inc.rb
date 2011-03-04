# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:
    module Atomic #:nodoc:

      # This class provides atomic $inc behaviour.
      class Inc < Operation

        # Sends the atomic $inc operation to the database.
        #
        # @example Persist the new values.
        #   inc.persist
        #
        # @return [ Object ] The new integer value.
        #
        # @since 2.0.0
        def persist
          current = document[field] || 0
          document[field] = current + value
          document[field].tap do
            document.collection.update(document._selector, operation, options)
            document.changes.delete(field.to_s)
          end
        end

        private

        # Get the atomic operation to perform.
        #
        # @example Get the operation.
        #   inc.operation
        #
        # @return [ Hash ] The $push operation for the field and addition.
        #
        # @since 2.0.0
        def operation
          { "$inc" => { field => value } }
        end
      end
    end
  end
end
