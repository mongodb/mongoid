# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:
    module Atomic #:nodoc:

      # This class provides the ability to perform an explicit $addToSet
      # modification on a specific field.
      class AddToSet < Operation

        # Sends the atomic $addToSet operation to the database.
        #
        # @example Persist the new values.
        #   addToSet.persist
        #
        # @return [ Object ] The new array value.
        #
        # @since 2.0.0
        def persist
          document[field] = [] unless document[field]
          values = document.send(field)
          values.push(value) unless values.include?(value)
          values.tap do
            if document.persisted?
              document.collection.update(document._selector, operation("$addToSet"), options)
              document.changes.delete(field.to_s)
            end
          end
        end
      end
    end
  end
end
