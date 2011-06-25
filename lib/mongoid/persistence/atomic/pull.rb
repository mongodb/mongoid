# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:
    module Atomic #:nodoc:

      # This class provides the ability to perform an explicit $pull
      # modification on a specific field.
      class Pull < Operation

        # Sends the atomic $pull operation to the database.
        #
        # @example Persist the new values.
        #   pull.persist
        #
        # @return [ Object ] The new array value.
        #
        # @since 2.1.0
        def persist
          if document[field]
            values = document.send(field)
            values.delete(value)
            values.tap do
              collection.update(document._selector, operation("$pull"), options)
              document.changes.delete(field.to_s) if document.persisted?
            end
          else
            return nil
          end
        end
      end
    end
  end
end
