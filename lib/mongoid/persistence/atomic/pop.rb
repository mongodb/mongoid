# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:
    module Atomic #:nodoc:

      # This class provides the ability to perform an explicit $pop
      # modification on a specific field.
      class Pop < Operation

        # Sends the atomic $pop operation to the database.
        #
        # @example Persist the new values.
        #   pop.persist
        #
        # @return [ Object ] The new array value.
        #
        # @since 2.1.0
        def persist
          if document[field]
            values = document.send(field)
            value > 0 ? values.pop : values.shift
            values.tap do
              document.collection.update(document._selector, operation("$pop"), options)
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
