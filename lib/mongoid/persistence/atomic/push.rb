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
            document.collection.update(document._selector, operation("$push"), options)
            document.changes.delete(field.to_s)
          end
        end
      end
    end
  end
end
