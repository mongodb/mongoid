# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:
    module Atomic #:nodoc:

      # This class provides the ability to perform an explicit $push modification
      # on a specific field.
      class Push < Operation

        # Sends the atomic $push operation to the database.
        #
        # @example Persist the new values.
        #   push.persist
        #
        # @return [ Object ] The new array value.
        #
        # @since 2.0.0
        def persist
          document[field] = [] unless document[field]
          document.send(field).push(value).tap do |value|
            document.collection.update(document._selector, operation, options)
            document.changes.delete(field.to_s)
          end
        end

        private

        # Get the atomic operation to perform.
        #
        # @example Get the operation.
        #   push.operation
        #
        # @return [ Hash ] The $push operation for the field and addition.
        #
        # @since 2.0.0
        def operation
          { "$push" => { field => value } }
        end
      end
    end
  end
end
