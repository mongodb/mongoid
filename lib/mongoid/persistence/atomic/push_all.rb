# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:
    module Atomic #:nodoc:

      # This class provides the ability to perform an explicit $pushAll modification
      # on a specific field.
      class PushAll < Operation

        # Sends the atomic $pushAll operation to the database.
        #
        # @example Persist the new values.
        #   pushAll.persist
        #
        # @return [ Object ] The new array value.
        #
        # @since 2.1.0
        def persist
          document[field] = [] unless document[field]
          document.send(field).concat(value).tap do |value|
            document.collection.update(document._selector, operation("$pushAll"), options)
            document.changes.delete(field.to_s)
          end
        end
      end
    end
  end
end
