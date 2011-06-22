# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:
    module Atomic #:nodoc:

      # Performs atomic $unset operations.
      class Unset < Operation

        # Sends the atomic $unset operation to the database.
        #
        # @example Persist the new values.
        #   unset.persist
        #
        # @return [ nil ] The new value.
        #
        # @since 2.1.0
        def persist
          self.field = field.to_s
          document.attributes.delete(field)
          document.collection.update(document._selector, operation("$unset"), options)
          document.changes.delete(value)
        end
      end
    end
  end
end
